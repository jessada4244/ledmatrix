import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String _getAnimationDisplayText(String animation) {
  switch (animation) {
    case 'scrollLeft':
      return 'ข้อความเลื่อนไปทางซ้าย';
    case 'scrollRight':
      return 'ข้อความเลื่อนไปทางขวา';
    case 'scrollUp':
      return 'ข้อความเลื่อนขึ้นด้านบน';
    case 'scrollDown':
      return 'ข้อความเลื่อนลงด้านล่าง';
    case 'TD_LEDWriteText':
      return 'ข้อความแสดงคงที่';
    default:
      return 'N/A';
  }
}

String _getColorDisplayText(String color) {
  switch (color) {
    case 'myWHITE':
      return 'สีขาว';
    case 'myRED':
      return 'สีแดง';
    case 'myGREEN':
      return 'สีเขียว';
    case 'myBLUE':
      return 'สีน้ำเงิน';
    case 'myCYAN':
      return 'สีฟ้า';
    case 'myYELLOW':
      return 'สีเหลือง';
    default:
      return 'N/A';
  }
}

String _getSizeDisplayText(int textSize) {
  switch (textSize) {
    case 1:
      return 'ขนาดเล็ก';
    case 2:
      return 'ขนาดกลาง';
    case 3:
      return 'ขนาดใหญ่';
    default:
      return 'N/A';
  }
}
String _getOtherDisplayText(String additionalDisplay) {
  switch (additionalDisplay) {
    case 'showdate':
      return 'วันที่และเวลา';
    case 'showtemp':
      return 'อุณหภูมิและความชื้น';
    case 'showtempanddate':
      return 'วันที่เวลาและอุณหภูมิความชื้น';
    case 'noshowtimeandtemp':
      return 'ไม่แสดง';
    default:
      return 'N/A';
  }
}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timerForExpiry;
  DateTime? _currentTime;
  List<QueryDocumentSnapshot>? _cachedItems;
  bool _isFirstBuild = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();
    _timerForExpiry = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_cachedItems != null && _cachedItems!.isNotEmpty) {
        final now = DateTime.now();
        bool needsRefresh = false;

        for (var item in List.from(_cachedItems!)) {
          final data = item.data() as Map<String, dynamic>;
          final expiry = (data['expiry'] as Timestamp).toDate();

          if (now.isAfter(expiry)) {
            try {
              // Delete the item
              await _firestore.collection('items').doc(item.id).delete();

              // If this was the earliest item, handle relay state
              if (_cachedItems!.indexOf(item) == 0) {
                // First turn off
                await _firestore
                    .collection('relay')
                    .doc('Mm5iDgNLWB6ieIHLOkiZ')
                    .set({'relayState': 'off'});

                // Wait 7 seconds
                await Future.delayed(Duration(seconds: 7));

                // Then turn on
                await _firestore
                    .collection('relay')
                    .doc('Mm5iDgNLWB6ieIHLOkiZ')
                    .set({'relayState': 'on'});
              }
              needsRefresh = true;
            } catch (e) {
              print('Error deleting expired item: $e');
            }
          }
        }

        if (needsRefresh) {
          _refreshData();
        }
      }
    });

  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerForExpiry?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _refreshData();
      _isFirstBuild = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .orderBy('timestamp', descending: false)
          .get();
      if (mounted) {
        setState(() {
          _cachedItems = snapshot.docs;
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  String _calculateRemainingTime(DateTime expiry) {
    final now = _currentTime ?? DateTime.now();
    final remaining = expiry.difference(now);
    final isExpired = now.isAfter(expiry);

    return isExpired
        ? 'หมดเวลาแล้ว'
        : '${remaining.inHours.abs()} ชั่วโมง ${remaining.inMinutes.abs() % 60} นาที ${remaining.inSeconds.abs() % 60} วินาที';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('หน้าแรก',
            style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),),

          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout,color: Colors.black),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _cachedItems == null
            ? FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('items')
              .orderBy('timestamp', descending: false)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('ไม่มีข้อมูล'));
            }
            _cachedItems = snapshot.data!.docs;
            return _buildItemsList();
          },
        )
            : _buildItemsList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home,color: Colors.black,),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new),
            label: 'เปิด-ปิด อุปกรณ์',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/settings');
          }
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (_cachedItems == null || _cachedItems!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ไม่มีข้อมูล'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add,color: Colors.white,),
              label: Text('เพิ่มข้อมูล'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // สีพื้นหลังปุ่ม
                foregroundColor: Colors.white, // สีของข้อความในปุ่ม
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              onPressed: () async {
                await Navigator.pushNamed(context, '/crud');
                _refreshData();
              },
            ),
          ],
        ),
      );


  }

    final earliestItem = _cachedItems!.first;
    final earliestData = earliestItem.data() as Map<String, dynamic>;
    final expiry = (earliestData['expiry'] as Timestamp).toDate();
    final remainingText = _calculateRemainingTime(expiry);
    final now = _currentTime ?? DateTime.now();
    final isExpired = now.isAfter(expiry);

    return Column(
      children: [
        Text(
          'รายการที่กำลังทำงานอยู่',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อความ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),),
                      Text(
                        '${earliestData['message'] ?? 'ไม่มีข้อความ'}',
                      ),
                      SizedBox(height: 8),
                      Text('รูปแบบ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),),
                      Text(
                        '${_getAnimationDisplayText(earliestData['animation'] ?? 'N/A')}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text('ขนาด',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),),
                      Text(
                        '${_getSizeDisplayText(earliestData['textSize'] ?? 'N/A')}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text('สี',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),),
                      Text(
                        '${_getColorDisplayText(earliestData['color'] ?? 'N/A')}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text('การแสดงเพิ่มเติม',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),),
                      Text(
                        '${_getOtherDisplayText(earliestData['additionalDisplay'] ?? 'N/A')}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'กำลังทำงาน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'เวลาที่แสดง $remainingText',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExpired ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รายการข้อมูล',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add,color: Colors.white,),
                    label: Text('เพิ่มข้อมูล'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีของข้อความในปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/crud');
                      _refreshData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _cachedItems!.length,
            itemBuilder: (context, index) {
              final item = _cachedItems![index];
              final data = item.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['message'] ?? 'ไม่มีข้อความ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'รูปแบบ: ${_getAnimationDisplayText(data['animation'] ?? 'N/A')} | ขนาด: ${_getSizeDisplayText(data['textSize'] ?? 'N/A')}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/crud',
                                  arguments: {
                                    'id': item.id,
                                    'data': data,
                                  },
                                );
                                _refreshData();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _firestore
                                    .collection('items')
                                    .doc(item.id)
                                    .delete();
                                await _firestore
                                    .collection('relay')
                                    .doc('Mm5iDgNLWB6ieIHLOkiZ')
                                    .set({'relayState': 'off'});

                                // Wait 7 seconds
                                await Future.delayed(Duration(seconds: 7));

                                // Then turn on
                                await _firestore
                                    .collection('relay')
                                    .doc('Mm5iDgNLWB6ieIHLOkiZ')
                                    .set({'relayState': 'on'});
                                _refreshData();
                                setState(() {
                                  _cachedItems!.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}