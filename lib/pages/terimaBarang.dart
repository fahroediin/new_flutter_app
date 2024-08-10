import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'dart:math';
import 'package:new_flutter_app/pages/terimaBarangSuccess.dart';

class TransaksiTerimaServisPage extends StatefulWidget {
  const TransaksiTerimaServisPage({Key? key}) : super(key: key);

  @override
  _TransaksiTerimaServisPageState createState() =>
      _TransaksiTerimaServisPageState();
}

class _TransaksiTerimaServisPageState extends State<TransaksiTerimaServisPage> {
  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _namaBarangServisController =
      TextEditingController();
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  final _formKey = GlobalKey<FormState>();
  String _idTransaksi = '';
  String _formattedDateTime = '';
  List<Map<dynamic, dynamic>> _pelangganList = [];
  String? _selectedKodePelanggan;
  String _namaPelanggan = '';
  String _alamatPelanggan = '';
  String _noHpPelanggan = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchPelangganList();
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    _namaBarangServisController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _generateIdTransaksi();
    _updateDateTime();
  }

  void _generateIdTransaksi() {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('ddMMyyyy').format(now);
    final randomNumbers = List.generate(6, (_) => Random().nextInt(10));
    final idTransaksi = '$formattedDateTime-${randomNumbers.join('')}';

    setState(() {
      _idTransaksi = idTransaksi;
    });
  }

  void _updateDateTime() {
    setState(() {
      _formattedDateTime =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    });
  }

  Future<void> _fetchPelangganList() async {
    final snapshot = await _databaseReference.child('daftarPelanggan').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> list = [];
      data.forEach((key, value) {
        list.add({
          'kodePelanggan': key,
          'namaPelanggan': value['namaPelanggan'],
          'alamatPelanggan': value['alamat'],
          'noHpPelanggan': value['noHp'],
        });
      });
      setState(() {
        _pelangganList = list;
      });
    }
  }

  void _onKodePelangganChanged(String? newValue) {
    if (newValue != null) {
      final selectedPelanggan = _pelangganList
          .firstWhere((pelanggan) => pelanggan['kodePelanggan'] == newValue);
      setState(() {
        _selectedKodePelanggan = newValue;
        _namaPelanggan = selectedPelanggan['namaPelanggan'];
        _alamatPelanggan = selectedPelanggan['alamatPelanggan'];
        _noHpPelanggan = selectedPelanggan['noHpPelanggan'];
      });
    }
  }

  void _saveData() {
    if (_selectedKodePelanggan == null) {
      final snackBar = SnackBar(
        content: Text('Mohon pilih kode pelanggan terlebih dahulu'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    String keluhan = _keluhanController.text.trim();
    String namaBarangServis = _namaBarangServisController.text.trim();

    Map<String, dynamic> data = {
      'idServis': _idTransaksi,
      'dateTimeTerima': _formattedDateTime,
      'kodePelanggan': _selectedKodePelanggan!,
      'namaPelanggan': _namaPelanggan,
      'alamat': _alamatPelanggan,
      'noHp': _noHpPelanggan,
      'keluhan': keluhan,
      'namaBarangServis': namaBarangServis,
      'isDone': false,
    };

    DatabaseReference terimaBarangRef =
        _databaseReference.child('terimaBarang').child(_idTransaksi);

    terimaBarangRef.set(data).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TerimaBarangSuccess(
            idTransaksi: _idTransaksi,
            formattedDateTime: _formattedDateTime,
            kodePelanggan: _selectedKodePelanggan!,
            namaPelanggan: _namaPelanggan,
            keluhan: keluhan,
            namaBarangServis: namaBarangServis,
            alamatPelanggan: _alamatPelanggan,
            noHpPelanggan: _noHpPelanggan,
          ),
        ),
      );
    }).catchError((error) {
      final snackBar = SnackBar(
        content: Text('Gagal menyimpan data transaksi: $error'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _clearFields() {
    _keluhanController.clear();
    _namaBarangServisController.clear();
    setState(() {
      _selectedKodePelanggan = null;
      _namaPelanggan = '';
      _alamatPelanggan = '';
      _noHpPelanggan = '';
    });
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
        title: Text('Terima Barang Servis'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID Servis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _idTransaksi,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Tanggal dan Waktu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formattedDateTime,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Kode Pelanggan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedKodePelanggan,
                onChanged: _onKodePelangganChanged,
                items: _pelangganList.map((pelanggan) {
                  return DropdownMenuItem<String>(
                    value: pelanggan['kodePelanggan'],
                    child: Text(
                        '${pelanggan['kodePelanggan']} - ${pelanggan['namaPelanggan']}'),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Pilih kode pelanggan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Visibility(
                visible: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alamat Pelanggan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _alamatPelanggan,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No HP Pelanggan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _noHpPelanggan,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Text(
                'Nama Barang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _namaBarangServisController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan nama barang yang diservis',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Keluhan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _keluhanController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan keluhan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wajib diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 6, 108, 176),
                      ),
                      child: Text(
                        'Terima Barang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
