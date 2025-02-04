import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrudScreen extends StatefulWidget {
  String? itemId;

  CrudScreen({this.itemId});

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _nameController = TextEditingController();
  String _textDisplayStyle = 'scrollLeft';
  String _textSize = '1';
  String _selectedColor = 'myWHITE';
  String _additionalDisplay = 'noshowtimeandtemp';
  int _hours = 0;
  int _minutes = 0;
  int _scrollSpeed = 30;

  double _previewOffsetX = 0.0;
  double _previewOffsetY = 0.0;
  Timer? _previewTimer;

  @override
  void dispose() {
    _nameController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && widget.itemId == null) {
      widget.itemId = args['id'];
      if (widget.itemId != null) {
        _firestore.collection('items').doc(widget.itemId).get().then((doc) {
          if (doc.exists) {
            var data = doc.data();
            setState(() {
              _nameController.text = data?['message'] ?? '';
              _textDisplayStyle = data?['animation'] ?? 'scrollLeft';
              _textSize = (data?['textSize'] ?? '1').toString();
              _selectedColor = data?['color'] ?? 'myWHITE';
              _scrollSpeed = data?['scrollSpeed'] ?? 50;
              _additionalDisplay = data?['additionalDisplay'] ?? 'noshowtimeandtemp';
            });
          }
        }).catchError((error) {
          print('Error loading data: $error');
        });
      }
    }
  }


  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อความก่อนบันทึก')),
      );
      return;
    }
    if (_hours == 0 && _minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากำหนดเวลาการแสดงผล')),
      );
      return;
    }
    try {
      await _firestore.collection('items').add({
        'message': _nameController.text.trim(),
        'animation': _textDisplayStyle,
        'textSize': int.parse(_textSize),
        'color': _selectedColor,
        'scrollSpeed': _scrollSpeed,
        'additionalDisplay': _additionalDisplay,
        'expiry': Timestamp.fromDate(
            DateTime.now()
                .toLocal() // ใช้เวลาท้องถิ่น (UTC+7)
                .add(Duration(hours: _hours, minutes: _minutes))
        ),
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกสำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _updateItem(String itemId) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อความก่อนบันทึก')),
      );
      return;
    }

    try {
      await _firestore.collection('items').doc(itemId).update({
        'message': _nameController.text.trim(),
        'animation': _textDisplayStyle,
        'textSize': int.parse(_textSize),
        'color': _selectedColor,
        'scrollSpeed': _scrollSpeed,
        'additionalDisplay': _additionalDisplay,
        'expiry': Timestamp.fromDate(
            DateTime.now()
                .toLocal() // ใช้เวลาท้องถิ่น (UTC+7)
                .add(Duration(hours: _hours, minutes: _minutes))
        ),
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('แก้ไขสำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _saveOrUpdate() {
    if (widget.itemId == null) {
      _saveItem();
    } else {
      _updateItem(widget.itemId!);
    }
  }

  void _pickColor(String colorName) {
    setState(() {
      _selectedColor = colorName;
    });
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'myRED':
        return Colors.red;
      case 'myGREEN':
        return Colors.green;
      case 'myBLUE':
        return Colors.blue;
      case 'myCYAN':
        return Colors.cyan;
      case 'myYELLOW':
        return Colors.yellow;
      case 'myWHITE':
      default:
        return Colors.white;
    }
  }
  String _getAdditionalDisplayText() {
    switch (_additionalDisplay) {
      case 'showtemp':
        return 'อุณหภูมิ: 25°C ความชื้น: 65%';
      case 'showdate':
        return 'วันที่ 24/01/2025 เวลา 12:00:00';
      case 'showtempanddate':
        return 'วันที่ เวลา              อุณหภูมิ ความชื้น';

      case 'noshowtimeandtemp':
        return 'ยินดีต้อนรับ';
      default:
        return '';
    }
  }
  void _startPreviewAnimation() {
    _previewTimer?.cancel();
    _previewOffsetX = 0.0;
    _previewOffsetY = 0.0;

    if (_textDisplayStyle != 'TD_LEDWriteText') {
      _previewTimer = Timer.periodic(Duration(milliseconds: _scrollSpeed * 10), (timer) {
        setState(() {
          switch (_textDisplayStyle) {
            case 'scrollLeft':
              _previewOffsetX -= 2;
              if (_previewOffsetX < -MediaQuery.of(context).size.width) {
                _previewOffsetX = MediaQuery.of(context).size.width;
              }
              break;
            case 'scrollRight':
              _previewOffsetX += 2;
              if (_previewOffsetX > MediaQuery.of(context).size.width) {
                _previewOffsetX = -MediaQuery.of(context).size.width;
              }
              break;
            case 'scrollUp':
              _previewOffsetY -= 2;
              if (_previewOffsetY < -50) {
                _previewOffsetY = 50;
              }
              break;
            case 'scrollDown':
              _previewOffsetY += 2;
              if (_previewOffsetY > 50) {
                _previewOffsetY = -50;
              }
              break;
          }
        });
      });
    }
  }

  Widget _buildPreview() {
    return Card(
      elevation: 4,
      color: Colors.black,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'การแสดงผล',

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17
              ),
            ),
            SizedBox(height: 10),
            ClipRect(
              child: Container(
                height: 60,
                width: double.infinity,
                color: Colors.white30,
                child: Stack(
                  children: [
                    Positioned(
                      left: _textDisplayStyle == 'scrollLeft' || _textDisplayStyle == 'scrollRight'
                          ? _previewOffsetX
                          : 2,
                      top: _textDisplayStyle == 'scrollUp' || _textDisplayStyle == 'scrollDown'
                          ? _previewOffsetY
                          : 1,
                      child: Text(
                        _nameController.text.trim().isEmpty
                            ? 'ไม่มีข้อความ'
                            : _nameController.text,
                        style: TextStyle(
                          fontSize: double.parse(_textSize) * 16,
                          color: _getColorFromName(_selectedColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),
            // Additional display preview (static)
            ClipRect(
              child: Container(
                height: 50,  // ความสูงน้อยกว่าเพราะเป็นข้อความบรรทัดเดียว
                width: double.infinity,
                color: Colors.white30,
                child: Center(
                  child: Text(
                    _getAdditionalDisplayText(),
                    style: TextStyle(
                      fontSize: 14,  // ขนาดคงที่
                      color: Colors.white,  // สีคงที่
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'เพิ่มข้อความ' : 'แก้ไขข้อความ',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildPreview(),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // สีพื้นหลังปุ่ม
                  foregroundColor: Colors.white, // สีของข้อความในปุ่ม
                ),
                onPressed: _startPreviewAnimation,
                child: Text('ทดลองการแสดงผล'),
              ),
              // ฟอร์ม
              _buildForm(),
              SizedBox(height: 20),
              // พรีวิวข้อความ

              // ปุ่มบันทึกและพรีวิว
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีของข้อความในปุ่ม
                    ),
                    onPressed: _saveOrUpdate,
                    child: Text(widget.itemId == null ? 'บันทึก' : 'อัปเดต'),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'ข้อความ'),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _textDisplayStyle,
          decoration: InputDecoration(labelText: 'รูปแบบการแสดงผล'),
          items: [
            {'label': 'ข้อความแสดงคงที่', 'value': 'TD_LEDWriteText'},
            {'label': 'ข้อความเลื่อนไปทางซ้าย', 'value': 'scrollLeft'},
            {'label': 'ข้อความเลื่อนไปทางขวา', 'value': 'scrollRight'},
            {'label': 'ข้อความเลื่อนขึ้นด้านบน', 'value': 'scrollUp'},
            {'label': 'ข้อความเลื่อนลงด้านล่าง', 'value': 'scrollDown'},
          ].map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _textDisplayStyle = newValue!;
            });
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _textSize,
          decoration: InputDecoration(labelText: 'กำหนดขนาดตัวอักษร'),
          items: [
            {'label': 'ขนาดเล็ก', 'value': '1'},
            {'label': 'ขนาดกลาง', 'value': '2'},
            {'label': 'ขนาดใหญ่', 'value': '3'},
          ].map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _textSize = newValue!;
            });
          },
        ),
        SizedBox(height: 10),
        Text('เลือกสีข้อความ:'),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _buildColorButton('myWHITE', Colors.white),
            _buildColorButton('myRED', Colors.red),
            _buildColorButton('myGREEN', Colors.green),
            _buildColorButton('myBLUE', Colors.blue),
            _buildColorButton('myCYAN', Colors.cyan),
            _buildColorButton('myYELLOW', Colors.yellow),
          ],
        ),
        SizedBox(height: 10),
        Text('กำหนดเวลา:'),
        Row(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.access_time,color: Colors.white,),
              label: Text('กำหนดเวลา'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // สีพื้นหลังปุ่ม
                foregroundColor: Colors.white, // สีของข้อความในปุ่ม
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _hours, minute: _minutes),
                );
                if (pickedTime != null) {
                  setState(() {
                    _hours = pickedTime.hour;
                    _minutes = pickedTime.minute;
                  });
                }
              },
            ),
            Text('      $_hours ชั่วโมง $_minutes นาที'),
          ],
        ),
        SizedBox(height: 10),
        Text('ความเร็วในการเคลื่อนไหว:'),
        Slider(
          value: (30 - _scrollSpeed).toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          // label: '$_scrollSpeed',
          onChanged: (double value) {
            setState(() {
              _scrollSpeed = (30 - value).toInt();
            });
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _additionalDisplay,
          decoration: InputDecoration(labelText: 'การแสดงเพิ่มเติม'),
          items: [
            {'label': 'แสดงอุณหภูมิและความชื้น', 'value': 'showtemp'},
            {'label': 'แสดงวันที่และเวลา', 'value': 'showdate'},
            {
              'label': 'แสดงวันที่และเวลากับแสดงอุณหภูมิและความชื้น',
              'value': 'showtempanddate'
            },
            {'label': 'ไม่แสดง', 'value': 'noshowtimeandtemp'},
          ].map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _additionalDisplay = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorButton(String colorName, Color color) {
    return GestureDetector(
      onTap: () => _pickColor(colorName),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: _selectedColor == colorName ? Colors.black : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }
}
