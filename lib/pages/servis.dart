import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'servisSuccess.dart';

class ServisPage extends StatefulWidget {
  @override
  _ServisPageState createState() => _ServisPageState();
}

class _ServisPageState extends State<ServisPage> {
  final _formKey = GlobalKey<FormState>();
  String? _idServis;
  String? _kodePelanggan;
  String? _namaPelanggan;
  String? _keluhan;
  String _formattedDateTime = '';
  double _totalBayar = 0;
  double _bayar = 0;
  double _biayaServis = 0;
  double _kembalian = 0;
  double _diskon = 0;
  List<Map<String, dynamic>> _pelangganList = [];
  final TextEditingController _kodePelangganController =
      TextEditingController();
  final TextEditingController _namaPelangganController =
      TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  List<Map<dynamic, dynamic>> barangList = [];
  List<Map<dynamic, dynamic>> filteredbarangList = [];
  List<Map<String, dynamic>> selectedbarangs = [];
  TextEditingController _catatanServisController = TextEditingController();
  TextEditingController diskonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    updateDateTime();
    getPelangganList();
  }

  void initializeFirebase() async {
    await Firebase.initializeApp();
  }

  void generateIdServis() {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('ddMMyyyy').format(now);
    final randomNumbers = List.generate(
      6,
      (_) => Random().nextInt(10),
    );
    final idServis = '$formattedDateTime-${randomNumbers.join('')}';

    setState(() {
      _idServis = idServis;
    });
  }

  void updateDateTime() {
    setState(() {
      _formattedDateTime =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    });
  }

// Calculate total price before discount
  double calculateTotalPriceBeforeDiscount() {
    double totalHarga = 0;
    for (Map<String, dynamic> item in _items) {
      int hargaBarang = item['hargaBarang'];
      int jumlahBarang = item['jumlahBarang'];
      totalHarga += hargaBarang * jumlahBarang;
    }
    return totalHarga;
  }

  /// Calculate total price after discount
  double calculateTotalPriceAfterDiscount(double discount) {
    const double minDiscountPercentage = 0.0;
    const double maxDiscountPercentage = 20.0;
    double validDiscount =
        discount.clamp(minDiscountPercentage, maxDiscountPercentage);

    double totalHarga = calculateTotalPriceBeforeDiscount();
    double discountAmount = totalHarga * validDiscount / 100;
    return totalHarga - discountAmount;
  }

  void _calculateTotalHarga() {
    double totalHarga = calculateTotalPriceBeforeDiscount();
    double discountAmount = _diskon;
    double totalHargaAfterDiscount = totalHarga - discountAmount;
    setState(() {
      _totalBayar = totalHargaAfterDiscount;
      calculateKembalian(); // Menghitung kembalian saat totalBayar diperbarui
    });
  }

  void calculateKembalian() {
    double kembalian = _bayar - (_totalBayar + _biayaServis);
    setState(() {
      _kembalian = kembalian;
    });
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_bayar < (_totalBayar + _biayaServis)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nominal Bayar Kurang'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
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
      saveServisData();
    }
  }

  void saveServisData() {
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child('transaksiServis');
    DatabaseReference terimaBarangRef =
        FirebaseDatabase.instance.reference().child('terimaBarang');

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
        'jumlahBarang': jumlahBarang,
      };
    }).toList();

    double diskon = double.tryParse(diskonController.text) ?? 0;
    double totalHarga = 0;
    int totaljumlahBarang = 0; // Menyimpan total jumlahBarang

    for (var item in _items) {
      double harga = double.tryParse(item['hargaBarang'].toString()) ?? 0;
      int jumlah = int.tryParse(item['jumlahBarang'].toString()) ?? 0;
      totalHarga += harga * jumlah; // Perbaikan perhitungan totalHargaBarang
      totaljumlahBarang +=
          jumlah; // Menambahkan jumlahBarang ke totaljumlahBarang
    }

    double totalDiskon = totalHarga * (diskon / 100); // Calculate totalDiskon

    double hargaAkhir = totalHarga - totalDiskon;
    double totalAkhir = hargaAkhir + _biayaServis;

    // Mendapatkan bulan dari dateTime
    String bulan = DateFormat('MMMM y', 'id_ID').format(DateTime.now());

    Map<String, dynamic> data = {
      'idServis': _idServis,
      'dateTime': _formattedDateTime,
      'bulan': bulan, // Menambahkan property 'bulan'
      'kodePelanggan': _kodePelangganController.text,
      'namaPelanggan': _namaPelangganController.text,
      'keluhan': _keluhanController.text,
      'catatan': _catatanServisController.text,
      'items': _items,
      'jumlahItem': totaljumlahBarang,
      'diskon': diskon,
      'totalDiskon': totalDiskon,
      'totalHargaBarang': totalHarga,
      'hargaAkhir': _totalBayar,
      'biayaServis': _biayaServis,
      'totalAkhir': totalAkhir,
      'bayar': _bayar,
      'kembalian': _kembalian,
      'isDone': true
    };

    reference.push().set(data).then((_) {
      terimaBarangRef.child(_idServis!).update({'isDone': true}).then(
        (_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServisSuccessPage(
                idServis: data['idServis'],
                dateTime: data['dateTime'] ?? '',
                kodePelanggan: data['kodePelanggan'],
                namaPelanggan: data['namaPelanggan'],
                kerusakan: data['keluhan'],
                catatan: data['catatan'],
                items: data['items'],
                totalHarga: data['totalHargaBarang'],
                diskon: data['diskon'],
                biayaServis: data['biayaServis'],
                hargaAkhir: data['hargaAkhir'],
                bayar: data['bayar'],
                kembalian: data['kembalian'],
              ),
            ),
          );
        },
      );
    });
  }

  void _selectPelanggan(String? value) {
    setState(() {
      if (value != null) {
        List<String> parts = value.split(' - ');
        if (parts.length >= 2) {
          _idServis = parts[0];
          _namaPelanggan = parts[1];
          _kodePelanggan = _pelangganList.firstWhere((pelanggan) =>
              pelanggan['idServis'] == _idServis)['kodePelanggan'];
          _keluhan = _pelangganList.firstWhere(
              (pelanggan) => pelanggan['idServis'] == _idServis)['keluhan'];

          _kodePelangganController.text = _kodePelanggan!;
          _namaPelangganController.text = _namaPelanggan!;
          _keluhanController.text = _keluhan!;
        }
      }
    });
  }

  void getPelangganList() {
    FirebaseDatabase.instance
        .reference()
        .child('terimaBarang')
        .orderByChild('isDone')
        .equalTo(false) // Filter hanya yang isDone == false
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _pelangganList.clear();
          Map<dynamic, dynamic> values =
              event.snapshot.value as Map<dynamic, dynamic>;

          values.forEach((key, value) {
            String idServis = value['idServis'];
            String kodePelanggan = value['kodePelanggan'];
            String namaPelanggan = value['namaPelanggan'];
            String keluhan = value['keluhan'];

            _pelangganList.add({
              'idServis': idServis,
              'kodePelanggan': kodePelanggan,
              'namaPelanggan': namaPelanggan,
              'keluhan': keluhan,
            });
          });
        });
      }
    });
  }

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Map<dynamic, dynamic>> barangList = [];
        List<Map<dynamic, dynamic>> filteredbarangList = [];
        TextEditingController jumlahItemController = TextEditingController();
        TextEditingController searchController =
            TextEditingController(); // Tambahkan controller untuk TextField pencarian

        // Fungsi untuk memperbarui daftar barang berdasarkan pencarian
        void updateFilteredbarangList() {
          filteredbarangList = barangList.where((barang) {
            String namaBarang = barang['namaBarang'].toString().toLowerCase();
            String searchKeyword = searchController.text.toLowerCase();
            return namaBarang.contains(searchKeyword);
          }).toList();
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Daftar barang'),
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
                                  SizedBox(
                                      height:
                                          5), // Jarak antara teks dan teks yang ditambahkan
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
        if (jumlahItem <= stokBarang) {
          // Menambahkan pengecekan stok sebelum menambah item baru
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
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Kesalahan'),
            content:
                Text('Jumlah item lebih banyak / kurang dari stok yang ada'),
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
      int stokBarang = removedItem['stokBarang'];
      _updatestokBarang(idBarang, stokBarang);
    });
    _calculateTotalHarga();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Transaksi Servis'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
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
              // Dropdown for selecting customer based on kodePelanggan
              Text(
                'Data Servis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'ID Servis'),
                value:
                    _idServis != null ? '$_idServis - $_namaPelanggan' : null,
                onChanged: _selectPelanggan,
                items: _pelangganList.map((pelanggan) {
                  String displayText =
                      '${pelanggan['idServis']} - ${pelanggan['namaPelanggan']}';
                  return DropdownMenuItem<String>(
                    value: displayText,
                    child: Text(displayText),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih ID Servis terlebih dahulu';
                  }
                  return null;
                },
              ),
              Visibility(
                visible: false,
                child: TextField(
                  controller: _kodePelangganController,
                  decoration: InputDecoration(
                    labelText: 'Kode Pelanggan',
                  ),
                  readOnly: true,
                ),
              ),
              Visibility(
                visible: false,
                child: TextField(
                  controller: _namaPelangganController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pelanggan',
                  ),
                  readOnly: true,
                ),
              ),
              SizedBox(height: 10.0),
              Visibility(
                visible: true,
                child: TextField(
                  controller: _keluhanController,
                  decoration: InputDecoration(
                    labelText: 'Keluhan',
                  ),
                  readOnly: true,
                ),
              ),
              SizedBox(height: 10),
              Visibility(
                visible: true,
                child: TextField(
                  controller: _catatanServisController,
                  maxLines:
                      null, // Parameter maxLines: null akan membuatnya dapat menampilkan lebih dari satu baris
                  decoration: InputDecoration(
                    labelText: 'Catatan Servis',
                  ),
                ),
              ),

              SizedBox(height: 10),
              Text(
                'Barang yang diganti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
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
                          Text('ID barang: ${item['idBarang']}'),
                          Text('Harga barang: ${item['hargaBarang']}'),
                          Text('Jumlah barang: ${item['jumlahBarang']}'),
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
                                content: Text('Hapus item?'),
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
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Harga (barang)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    'Rp ${formatCurrency(_totalBayar.toInt())}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Biaya Servis'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  double biayaServis = double.tryParse(value) ?? 0;
                  setState(() {
                    _biayaServis = biayaServis;
                    calculateKembalian();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kolom bayar tidak boleh kosong';
                  }
                  return null;
                },
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
                    _totalBayar = calculateTotalPriceAfterDiscount(discount);
                    calculateKembalian();
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Bayar'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kolom bayar tidak boleh kosong';
                  }
                },
                onChanged: (value) {
                  double bayar = double.tryParse(value) ?? 0;
                  setState(() {
                    _bayar = bayar;
                    calculateKembalian();
                  });
                },
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Biaya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${formatCurrency((_totalBayar + _biayaServis).toInt())}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
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
              SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 108, 176),
                ),
                child: _isLoading
                    ? CircularProgressIndicator() // Tampilkan indikator loading jika _isLoading bernilai true
                    : Text(
                        'Proses Servis',
                        style: TextStyle(
                            color: Colors
                                .white), // Mengubah warna teks menjadi putih
                      ),
                onPressed: _isLoading
                    ? null
                    : submitForm, // Nonaktifkan tombol saat loading
              ),
            ],
          ),
        ),
      ),
    );
  }
}
