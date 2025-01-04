import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการข้อมูล'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/crud'); // เปิดหน้าเพิ่มข้อมูลใหม่
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('items')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูล'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['message'] ?? 'ไม่มีข้อความ'),
                subtitle: Text(
                    'รูปแบบ: ${data['animation'] ?? 'N/A'} | ขนาด: ${data['textSize'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _firestore.collection('items').doc(item.id).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/crud',
                    arguments: {
                      'id': item.id,
                      'data': data,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
