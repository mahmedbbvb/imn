import 'package:flutter/material.dart';
import 'my_qr_screen.dart';
import 'scan_qr_screen.dart';

class AddContactScreen extends StatelessWidget {
  const AddContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Contact'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_rounded), text: 'My QR'),
              Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scan QR'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(
          children: [
            MyQRScreen(),
            ScanQRScreen(),
          ],
        ),
      ),
    );
  }
}
