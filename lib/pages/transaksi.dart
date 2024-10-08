import 'dart:ffi';
import 'dart:math';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'package:new_flutter_app/pages/transaksiSuccess.dart';
import 'package:intl/intl.dart';

class TransaksiPenjualanPage extends StatefulWidget {
  @override
  _TransaksiPenjualanPageState createState() => _TransaksiPenjualanPageState();
}

class _TransaksiPenjualanPageState extends State<TransaksiPenjualanPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _idPenjualan;
  String _formattedDateTime = '';
  String _formattedMonth = DateFormat('MM').format(DateTime.now());
  String? _namaPembeli;
  double _totalHarga = 0;
  double _bayar = 0;
  double _kembalian = 0;
  double harga = 0;
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> selectedbarangs = [];
  TextEditingController diskonController = TextEditingController();
  Query dbRef = FirebaseDatabase.instance.reference().child('daftarBarang');
  TextEditingController searchController = TextEditingController();
  TextEditingController bayarController = TextEditingController();

  List<Map> searchResultList = [];
  List<Map> barangList = [];
  List<Map> filteredList = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    generateIdPenjualan();
    _updateDateTime();
    filteredList = [];
  }

  void searchList(String query) {
    searchResultList.clear();

    if (query.isNotEmpty) {
      List<Map> searchResult = barangList
          .where((barang) =>
              barang['namaBarang']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              barang['specbarang'].toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (searchResult.isNotEmpty) {
        setState(() {
          isSearching = true;
          searchResultList.add(searchResult.first);
        });
      } else {
        setState(() {
          isSearching = false;
        });
      }
    } else {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _updateDateTime() {
    setState(() {
      _formattedDateTime =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(_selectedDate);
      _formattedMonth = DateFormat('MM').format(_selectedDate);
    });
  }

  List<String> _namaBulan = [
    '', // Indeks 0 tidak digunakan
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  void initializeFirebase() async {
    await Firebase.initializeApp();
  }

  void generateIdPenjualan() {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('ddMMyyyy').format(now);
    final randomNumbers = List.generate(
      6,
      (_) => Random().nextInt(10),
    );
    final idPenjualan = '$formattedDateTime-${randomNumbers.join('')}';

    setState(() {
      _idPenjualan = idPenjualan;
    });
  }

  void _calculateTotalHarga() {
    double totalHarga = 0;
    for (var item in _items) {
      double harga = double.tryParse(item['hargaBarang'].toString()) ?? 0;
      int jumlah = int.tryParse(item['jumlahBarang'].toString()) ?? 0;
      totalHarga += harga * jumlah;
    }

    double diskon = double.tryParse(diskonController.text) ?? 0;
    double diskonAmount =
        totalHarga * (diskon / 100); // Mengubah diskon menjadi persen
    totalHarga -= diskonAmount;

    setState(() {
      _totalHarga = totalHarga;
    });
  }

  void _calculateKembalian(double jumlahBayar) {
    double kembalian = jumlahBayar - _totalHarga;
    setState(() {
      _kembalian = max(0, kembalian);
    });
  }

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if the buyer's name is empty or null
      if (_namaPembeli == null || _namaPembeli!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nama pembeli tidak boleh kosong'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if there are any selected spare parts
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih barang terlebih dahulu'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return; // Exit the method if there are no selected spare parts
      }

      // Update the stock of spare parts
      for (var barang in selectedbarangs) {
        DatabaseReference barangRef = FirebaseDatabase.instance
            .reference()
            .child('daftarBarang')
            .child(barang['idBarang']);
        int stokBarang = barang['stokBarang'];
        int jumlahBarang = barang['jumlahBarang'];
        barangRef.update({'stokBarang': stokBarang - jumlahBarang});
      }

      // Check if the payment amount is sufficient
      if (_totalHarga > _bayar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nominal Bayar Kurang'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return; // Exit the method if the payment amount is insufficient
      }
      // Check for internet connectivity
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada koneksi internet'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      // Save the transaction data
      saveTransaksiPenjualan();
    }
  }

  void saveTransaksiPenjualan() {
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child('transaksiPenjualan');

    List<Map<String, dynamic>> items = _items.map((item) {
      int jumlahBarang = item['jumlahBarang'];
      int totalJumlahItem = 0;

      // Menghitung total jumlahItem berdasarkan jumlahBarang
      if (jumlahBarang != null) {
        totalJumlahItem = jumlahBarang.toInt();
      }

      return {
        'idBarang': item['idBarang'],
        'namaBarang': item['namaBarang'],
        'hargaBarang': item['hargaBarang'].toInt(),
        'merkbarang': item['merkbarang'],
        'jumlahBarang': jumlahBarang,
      };
    }).toList();

    double diskon = double.tryParse(diskonController.text) ?? 0;

    double totalHarga = 0;
    int totaljumlahBarang = 0; // Menyimpan total jumlahBarang

    for (var item in _items) {
      double harga = double.tryParse(item['hargaBarang'].toString()) ?? 0;
      int jumlah = int.tryParse(item['jumlahBarang'].toString()) ?? 0;
      totalHarga += harga * jumlah;
      totaljumlahBarang +=
          jumlah; // Menambahkan jumlahBarang ke totaljumlahBarang
    }

    double totalDiskon = totalHarga * (diskon / 100); // Calculate totalDiskon

    double hargaAkhir = totalHarga - totalDiskon;
    String namaBulan = DateFormat('MMMM yyyy', 'id_ID').format(
        _selectedDate); // Menggunakan DateFormat untuk mendapatkan nama bulan

    Map<String, dynamic> data = {
      'idPenjualan': _idPenjualan,
      'bulan': namaBulan,
      'dateTime': _formattedDateTime,
      'namaPembeli': _namaPembeli,
      'items': items,
      'totalHarga': totalHarga,
      'hargaAkhir': hargaAkhir,
      'jumlahItem': totaljumlahBarang,
      'bayar': _bayar,
      'kembalian': _kembalian,
      'diskon': diskon.toInt(),
      'totalDiskon': totalDiskon,
    };

    reference.push().set(data).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransaksiSuccessPage(
            idPenjualan: data['idPenjualan'],
            tanggalTransaksi: data['dateTime'] ?? '',
            namaPembeli: data['namaPembeli'],
            totalHarga: totalHarga,
            bayar: data['bayar'].toDouble(),
            kembalian: _kembalian.toDouble(),
            items: List<Map<String, dynamic>>.from(data['items']),
            diskon: diskon.toDouble(),
            hargaAkhir: hargaAkhir,
          ),
        ),
      );
    });
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Map<String, dynamic>> selectedbarangs = [];
        List<Map<dynamic, dynamic>> barangList = [];
        List<Map<dynamic, dynamic>> filteredbarangList = [];
        TextEditingController jumlahItemController = TextEditingController();
        TextEditingController searchController =
            TextEditingController(); // Tambahkan controller untuk TextField pencarian

        // Fungsi untuk memperbarui daftar barang berdasarkan pencarian
        void updateFilteredbarangList() {
          filteredbarangList = barangList.where((barang) {
            String namaBarang = barang['namaBarang'].toString().toLowerCase();
            String specbarang = barang['specbarang'].toString().toLowerCase();
            String searchKeyword = searchController.text.toLowerCase();
            // Filter berdasarkan kategori "Penjualan" dan pencarian
            return (barang['kategori'] == 'Penjualan') &&
                (namaBarang.contains(searchKeyword) ||
                    specbarang.contains(searchKeyword));
          }).toList();
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Daftar Barang'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  children: [
                    TextField(
                      controller:
                          searchController, // Tambahkan controller ke TextField pencarian
                      decoration: InputDecoration(
                        labelText: 'Cari Nama Barang',
                      ),
                      onChanged: (value) {
                        updateFilteredbarangList();
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<DataSnapshot>(
                        future: FirebaseDatabase.instance
                            .reference()
                            .child('daftarBarang')
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DataSnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasData &&
                              snapshot.data != null) {
                            DataSnapshot dataSnapshot = snapshot.data!;
                            Map<dynamic, dynamic>? data =
                                dataSnapshot.value as Map<dynamic, dynamic>?;

                            if (data != null) {
                              barangList = [];
                              data.forEach((key, value) {
                                barangList
                                    .add(Map<dynamic, dynamic>.from(value));
                              });
                              updateFilteredbarangList(); // Perbarui daftar barang berdasarkan data terbaru
                            }

                            if (filteredbarangList.isEmpty) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      'Data tidak ditemukan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Pastikan ejaan dengan benar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredbarangList.length,
                              separatorBuilder:
                                  (BuildContext context, int index) => Divider(
                                color: Colors.grey,
                                thickness: 1.0,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                Map<dynamic, dynamic> barang =
                                    filteredbarangList[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromARGB(255, 237, 85, 85)
                                            .withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '${barang['namaBarang']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 8.0),
                                        Text(
                                          'ID: ${barang['idBarang']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        SizedBox(height: 4.0),
                                        Text(
                                          'Harga: Rp ${formatCurrency(barang['hargaBarang'])}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 18),
                                        ),
                                        SizedBox(height: 4.0),
                                        Text(
                                          'Stok: ${barang['stokBarang']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        SizedBox(height: 8.0),
                                      ],
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Jumlah'),
                                            content: TextField(
                                              controller: jumlahItemController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Jumlah Item',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  int jumlahItem = int.tryParse(
                                                          jumlahItemController
                                                              .text) ??
                                                      0;
                                                  int stokBarang =
                                                      barang['stokBarang'] ?? 0;
                                                  if (jumlahItem > 0 &&
                                                      jumlahItem <=
                                                          stokBarang) {
                                                    _selectItem(
                                                      Map<String, dynamic>.from(
                                                          barang),
                                                      jumlahItem,
                                                    );
                                                  } else {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title:
                                                              Text('Kesalahan'),
                                                          content: Text(
                                                              'Jumlah item lebih banyak dari stok yang ada'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: Text('OK'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Text('Data tidak ditemukan'),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectItem(Map<dynamic, dynamic> barang, int jumlahItem) {
    int stokBarang = (barang['stokBarang']) ?? 0;

    if (jumlahItem > 0 && jumlahItem <= stokBarang) {
      // Check if the barang already exists in the list
      int existingItemIndex =
          _items.indexWhere((item) => item['idBarang'] == barang['idBarang']);

      if (existingItemIndex != -1) {
        // If the barang already exists, update the quantity instead of adding a new item
        int existingQuantity = _items[existingItemIndex]['jumlahBarang'];
        int newQuantity = existingQuantity + jumlahItem;
        if (newQuantity <= stokBarang) {
          setState(() {
            _items[existingItemIndex]['jumlahBarang'] = newQuantity;
          });
          _calculateTotalHarga();
          // Update stokBarang in the database
          _updatestokBarang(barang['idBarang'], stokBarang - jumlahItem);
          Navigator.of(context).pop(); // Menutup dialog
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Kesalahan'),
                content: Text('Jumlah item lebih banyak dari stok yang ada'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
          return; // Menambahkan return agar stok tidak dikurangi jika terjadi kesalahan
        }
      } else {
        setState(() {
          _items.add({
            'idBarang': barang['idBarang'],
            'namaBarang': barang['namaBarang'],
            'hargaBarang': barang['hargaBarang'].toInt(),
            'jumlahBarang': jumlahItem,
            'stokBarang': stokBarang,
          });
        });
        _calculateTotalHarga();
        // Update stokBarang in the database
        _updatestokBarang(barang['idBarang'], stokBarang - jumlahItem);
        Navigator.of(context).pop(); // Menutup dialog
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Kesalahan'),
            content: Text('Jumlah item lebih banyak dari stok yang ada'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _updatestokBarang(String idBarang, int stokBarang) {
    DatabaseReference barangRef = FirebaseDatabase.instance
        .reference()
        .child('daftarBarang')
        .child(idBarang);
    barangRef.update({'stokBarang': stokBarang});
  }

  void _updateItem(int index, String field, dynamic value) {
    setState(() {
      _items[index][field] = value;
    });
    _calculateTotalHarga();
  }

  void _removeItem(int index) {
    setState(() {
      Map<String, dynamic> removedItem = _items.removeAt(index);
      String idBarang = removedItem['idBarang'];
      int jumlahBarang = removedItem['jumlahBarang'];
      int stokBarang = removedItem['stokBarang'];
      _updatestokBarang(idBarang, stokBarang);
    });
    _calculateTotalHarga();
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _items.forEach((item) {
              _updatestokBarang(item['idBarang'], item['stokBarang']);
            });

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
        title: Text('Transaksi Penjualan'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'ID Penjualan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: _idPenjualan,
                readOnly: true,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(),
              ),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal dan Waktu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _formattedDateTime,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama Pembeli'),
                textCapitalization: TextCapitalization.words,
                onSaved: (value) {
                  _namaPembeli = value ?? 'Anonim';
                },
                initialValue: 'Anonim',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Pembeli tidak boleh kosong';
                  }
                  return null; // Return null if the value is valid
                },
              ),
              SizedBox(height: 10),
              Text(
                'Data Barang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> item = _items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['namaBarang']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID Barang: ${item['idBarang']}'),
                          Text('Harga Barang: ${item['hargaBarang']}'),
                          Text('Jumlah Barang: ${item['jumlahBarang']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Konfirmasi'),
                                content: Text(
                                    'Apakah Anda yakin ingin menghapus item ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Tidak'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _removeItem(index);
                                    },
                                    child: Text('Ya'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 6, 108, 176),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _addItem,
                  borderRadius: BorderRadius.circular(25),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    'Rp ${formatCurrency(_totalHarga.toInt())}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: diskonController,
                decoration: InputDecoration(
                  labelText: 'Diskon (%)',
                  hintText: 'Maksimal diskon 0 s/d 25',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^0*(?:[0-9][0-9]?|25)$')),
                ],
                onChanged: (value) {
                  double discount = double.tryParse(value) ?? 0;

                  if (discount > 25) {
                    diskonController.text =
                        ''; // Reset to empty if the value exceeds the limit
                    discount = 0;
                    // Show the snackbar when the discount exceeds 25
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maksimal diskon adalah 25%'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  setState(() {
                    _calculateTotalHarga();
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: bayarController,
                decoration: InputDecoration(labelText: 'Bayar'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                onChanged: (value) {
                  setState(() {
                    _bayar = double.parse(value);
                    _calculateKembalian(_bayar);
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Kolom bayar tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kembalian',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    'Rp ${formatCurrency(_kembalian.toInt())}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 108, 176),
                ),
                child: Text(
                  'Proses Transaksi',
                  style: TextStyle(
                      color: Colors.white), // Mengubah warna teks menjadi putih
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
