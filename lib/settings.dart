import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isDeviceOn = false;
  int _selectedIndex = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelayState();
  }

  Future<void> _loadRelayState() async {
    try {
      final doc = await _firestore
          .collection('relay')
          .doc('Mm5iDgNLWB6ieIHLOkiZ')
          .get();

      if (doc.exists && doc.data() != null) {
        final relayState = doc.data()!['relayState'];
        print('Loaded relay state: $relayState');

        setState(() {
          isDeviceOn = relayState == 'on'  ? relayState == 'on' : false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading relay state: $e');
      isLoading = false;
    }
  }

  Future<void> _updateRelayState(bool value) async {
    try {
      await _firestore
          .collection('relay')
          .doc('Mm5iDgNLWB6ieIHLOkiZ')
          .set({
        'relayState': value ? 'on' : 'off',
      });

      setState(() {
        isDeviceOn = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตสถานะสำเร็จ')),
      );
    } catch (e) {
      print('Error updating relay state: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ตั้งค่า'),
          automaticallyImplyLeading: false,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            ListTile(
              title: Text('เปิด/ปิด อุปกรณ์'),
              trailing: Switch(
                value: isDeviceOn,
                onChanged: (bool value) => _updateRelayState(value),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'หน้าแรก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.power_settings_new),
              label: 'ตั้งค่า',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 0) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
        ),
      ),
    );
  }
}