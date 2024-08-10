import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:new_flutter_app/drawer/barang.dart';
import 'dart:math';

class InputbarangPage extends StatefulWidget {
  const InputbarangPage({Key? key}) : super(key: key);

  @override
  _InputbarangPageState createState() => _InputbarangPageState();
}

class _InputbarangPageState extends State<InputbarangPage>
    with TickerProviderStateMixin {
  final TextEditingController _idBarangController = TextEditingController();
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _hargaBarangController = TextEditingController();
  final TextEditingController _stokBarangController = TextEditingController();

  final databaseReference = FirebaseDatabase.instance.reference();
  List<Map<dynamic, dynamic>> barangList = [];
  List<Map<dynamic, dynamic>> filteredbarangList = [];

  @override
  void initState() {
    super.initState();
    _idBarangController.text = generateID();
    fetchData();
  }

  Future<void> fetchData() async {
    DataSnapshot dataSnapshot =
        await databaseReference.child('daftarBarang').get() as DataSnapshot;
    if (dataSnapshot != null && dataSnapshot.value != null) {
      Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
      barangList = data.entries
          .map((entry) => Map<dynamic, dynamic>.from(entry.value))
          .toList();
      filteredbarangList = barangList;
      setState(() {});
    }
  }

  String generateID() {
    // Generate 4 random digits
    String randomDigits = '';
    for (int i = 0; i < 4; i++) {
      randomDigits += '${Random().nextInt(10)}';
    }

    return 'KB$randomDigits';
  }

  void saveData() {
    String idBarang = _idBarangController.text.trim();
    String namaBarang = _namaBarangController.text.trim();
    int hargaBarang = int.tryParse(_hargaBarangController.text.trim()) ?? 0;
    int stokBarang = int.tryParse(_stokBarangController.text.trim()) ?? 0;

    if (idBarang.isNotEmpty && namaBarang.isNotEmpty && hargaBarang > 0) {
      databaseReference.child('daftarBarang').child(idBarang).set({
        'idBarang': idBarang,
        'namaBarang': namaBarang,
        'hargaBarang': hargaBarang,
        'stokBarang': stokBarang,
      }).then((_) {
        final snackBar = SnackBar(
          content: Text('Berhasil menyimpan data'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        _clearFields();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BarangPage()),
        );
      }).catchError((error) {
        final snackBar = SnackBar(
          content: Text('Gagal menyimpan data suku cadang: $error'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    } else {
      final snackBar = SnackBar(
        content: Text('Mohon lengkapi semua field'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _clearFields() {
    _idBarangController.clear();
    _namaBarangController.clear();
    _hargaBarangController.clear();
    _stokBarangController.clear();
  }

  @override
  void dispose() {
    _idBarangController.dispose();
    _namaBarangController.dispose();
    _hargaBarangController.dispose();
    _stokBarangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 500),
                pageBuilder: (_, __, ___) => BarangPage(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        title: Text('Tambah barang'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _idBarangController,
              enabled: false, // Set TextField menjadi read-only
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ID barang',
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _namaBarangController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nama barang',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _hargaBarangController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Harga barang',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _stokBarangController,
              keyboardType: TextInputType.number, // Set keyboard type to number
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Stok barang',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 6, 108, 176),
              ),
              child: Text(
                'Simpan',
                style: TextStyle(
                    color: Colors.white), // Mengatur warna teks menjadi putih
              ),
            ),
          ],
        ),
      ),
    );
  }
}
