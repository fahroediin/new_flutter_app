import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class InputPelangganPage extends StatefulWidget {
  const InputPelangganPage({Key? key}) : super(key: key);

  @override
  _InputPelangganPageState createState() => _InputPelangganPageState();
}

class _InputPelangganPageState extends State<InputPelangganPage>
    with TickerProviderStateMixin {
  final TextEditingController _kodePelangganAwalanController =
      TextEditingController(text: 'C');
  final TextEditingController _kodePelangganNomorController =
      TextEditingController();
  final TextEditingController _namaPelangganController =
      TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();
  List<Map<dynamic, dynamic>> _dataList = [];

  final databaseReference = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    _kodePelangganNomorController.text = _generateNomor();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _generateNomor() {
    // Generate a random 6-digit number
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> saveData() async {
    String kodePelanggan = _kodePelangganAwalanController.text.trim() +
        _kodePelangganNomorController.text.trim();
    String namaPelanggan = _namaPelangganController.text.trim();
    String alamat = _alamatController.text.trim();
    String noHp = _noHpController.text.trim();
    if (namaPelanggan.isNotEmpty &&
        kodePelanggan.isNotEmpty &&
        alamat.isNotEmpty &&
        noHp.isNotEmpty) {
      DatabaseReference pelangganRef =
          _databaseReference.child('daftarPelanggan').child(kodePelanggan);
      try {
        DataSnapshot snapshot = await pelangganRef.get();
        if (snapshot.value != null) {
          // Data dengan kode pelanggan tersebut telah terdaftar
          final snackBar = SnackBar(
            content: Text('Kode pelanggan sudah terdaftar'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          // Data belum terdaftar, simpan data baru ke database
          await pelangganRef.set({
            'namaPelanggan': namaPelanggan,
            'kodePelanggan': kodePelanggan,
            'alamat': alamat,
            'noHp': noHp,
          });
          final snackBar = SnackBar(
            content: Text('Data pelanggan berhasil disimpan'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          // Clear fields and navigate to the homepage
          _clearFields();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        }
      } catch (error) {
        final snackBar = SnackBar(
          content: Text('Gagal menyimpan data pelanggan: $error'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      // Show error messages for empty fields
      final snackBar = SnackBar(
        content: Text('Mohon isi semua data terlebih dahulu'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _clearFields() {
    _kodePelangganAwalanController.clear();
    _kodePelangganNomorController.clear();
    _namaPelangganController.clear();
    _alamatController.clear();
    _noHpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    HomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var begin = Offset(1.0, 0.0);
                  var end = Offset.zero;
                  var curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: Duration(milliseconds: 300),
              ),
            );
          },
        ),
        title: Text('Input Pelanggan'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kode Pelanggan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 100, // Sesuaikan lebar sesuai kebutuhan
                    child: TextFormField(
                      controller: _kodePelangganAwalanController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Awalan',
                        prefixStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors
                              .black, // Sesuaikan dengan warna teks yang diinginkan
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      enabled: false, // Membuat input field tidak bisa di-edit
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _kodePelangganNomorController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nomor',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textAlign: TextAlign.center,
                      enabled: false, // Disable editing
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        if (value.length != 6) {
                          return 'Harus terdiri dari 6 digit angka';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Nama Pelanggan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _namaPelangganController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan nama pelanggan',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(255),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z/]')),
                ],
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wajib diisi';
                  }
                  if (value.length < 3) {
                    return 'Minimal 3 huruf';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Alamat:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Alamat',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z 0-9/]')),
                ],
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 20),
              Text(
                'Nomor HP:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _noHpController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nomor HP',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wajib diisi';
                  }
                  if (value.length < 11 || value.length > 13) {
                    return 'Harus terdiri dari 11 hingga 13 digit angka';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveData,
                child: Text(
                  'Simpan',
                  style: TextStyle(
                      color: Colors.white), // Mengatur warna teks menjadi putih
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 108, 176),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
