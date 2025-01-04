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
  String _selectedColor = 'myBLACK';
  String _additionalDisplay = 'noshowtimeandtemp';
  int _hours = 0;
  int _minutes = 0;
  int _scrollSpeed = 50;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && widget.itemId == null) {
      widget.itemId = args['id'];
      print('Received itemId: ${widget.itemId}');
      if (widget.itemId != null) {
        _firestore.collection('items').doc(widget.itemId).get().then((doc) {
          if (doc.exists) {
            var data = doc.data();
            print('Loaded data: $data');
            setState(() {
              _nameController.text = data?['message'] ?? '';
              _textDisplayStyle = data?['animation'] ?? 'scrollLeft';
              _textSize = (data?['textSize'] ?? '1').toString();
              _selectedColor = data?['color'] ?? 'myBLACK';
              _scrollSpeed = data?['scrollSpeed'] ?? 50;
              _additionalDisplay = data?['additionalDisplay'] ?? 'noshowtimeandtemp';
            });
          } else {
            print('Document does not exist.');
          }
        }).catchError((error) {
          print('Error loading data: $error');
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      print('Fetching data for itemId: ${widget.itemId}');
      _firestore.collection('items').doc(widget.itemId).get().then((doc) {
        print('Document snapshot: ${doc.data()}');
        if (doc.exists) {
          var data = doc.data();
          setState(() {
            _nameController.text = data?['message'] ?? '';
            _textDisplayStyle = data?['animation'] ?? 'scrollLeft';
            _textSize = (data?['textSize'] ?? 1).toString();
            _selectedColor = data?['color'] ?? 'myBLACK';
            _scrollSpeed = data?['scrollSpeed'] ?? 50;
            _additionalDisplay = data?['additionalDisplay'] ?? 'noshowtimeandtemp';
          });
        } else {
          print('Document does not exist for itemId: ${widget.itemId}');
        }
      }).catchError((error) {
        print('Error fetching document: $error');
      });
    }
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อความก่อนบันทึก')),
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
        'expiry': DateTime.now()
            .add(Duration(hours: _hours, minutes: _minutes))
            .toIso8601String(),
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
        'expiry': DateTime.now()
            .add(Duration(hours: _hours, minutes: _minutes))
            .toIso8601String(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'เพิ่มข้อความ' : 'แก้ไขข้อความ'),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
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
                decoration: InputDecoration(labelText: 'ขนาดตัวอักษร'),
                items: [
                  {'label': 'เล็ก', 'value': '1'},
                  {'label': 'กลาง', 'value': '2'},
                  {'label': 'ใหญ่', 'value': '3'},
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
              Wrap(
                spacing: 10,
                children: [
                  _buildColorButton('myBLACK', Colors.black),
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
                  IconButton(
                    icon: Icon(Icons.access_time),
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
                  Text('$_hours ชั่วโมง $_minutes นาที'),
                ],
              ),
              SizedBox(height: 10),
              Text('ความเร็วในการเคลื่อนไหว: $_scrollSpeed'),
              Slider(
                value: _scrollSpeed.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: '$_scrollSpeed',
                onChanged: (double value) {
                  setState(() {
                    _scrollSpeed = value.toInt();
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveOrUpdate,
                child: Text(widget.itemId == null ? 'บันทึก' : 'อัปเดต'),
              ),
            ],
          ),
        ),
      ),
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
