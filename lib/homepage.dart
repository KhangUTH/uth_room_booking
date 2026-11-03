import "package:flutter/material.dart";
import "package:uth_room_booking/navbar/footer.dart";
import "package:uth_room_booking/navbar/header.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyHeader(
        name: 'Trương Minh Khang', // <-- điền tên SV/GV
        id: '077205002739', // <-- điền MSSV/MSGV
      ),
      body: Center(child: Text('Đang ở tab $_index')),
      bottomNavigationBar: MyFooter(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
