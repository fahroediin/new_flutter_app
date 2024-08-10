import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:new_flutter_app/drawer/about.dart';
import 'package:new_flutter_app/drawer/historiTerimaBarang.dart';
import 'package:new_flutter_app/drawer/pelanggan.dart';
import 'package:new_flutter_app/drawer/serviceReport.dart';
import 'package:new_flutter_app/drawer/transactionReport.dart';
import 'package:new_flutter_app/drawer/barang.dart';
import 'package:new_flutter_app/pages/insert_pelanggan.dart';
import 'package:new_flutter_app/pages/login_page.dart';
import 'package:new_flutter_app/pages/listbarang.dart';
import 'package:new_flutter_app/drawer/historiPenjualan.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:new_flutter_app/pages/servis.dart';
import 'package:new_flutter_app/pages/terimaBarang.dart';
import 'package:new_flutter_app/pages/transaksi.dart';
import 'package:new_flutter_app/drawer/historiServis.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _formattedDateTime = '';
  Map<dynamic, dynamic>? userData;
  DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();
  Query dbRefServis =
      FirebaseDatabase.instance.reference().child('transaksiServis');
  int countDataServis = 0;
  Query dbRefPenjualan =
      FirebaseDatabase.instance.reference().child('transaksiPenjualan');
  int countdDataPenjualan = 0;
  String nameController = '';
  String addressController = '';
  String selectedRole = 'Owner';

  @override
  void initState() {
    super.initState();
    fetchDataServis();
    fetchDataPenjualan();
    // _checkCurrentUser();
    formattedDateTime();
    initializeDateFormatting(
        'id_ID', null); // Initialize date formatting for Indonesian locale
    _databaseReference = FirebaseDatabase.instance.reference().child('user');
    getUserData();
    getUser();
  }

  void formattedDateTime() {
    setState(() {
      _formattedDateTime = DateFormat('dd/MM/yyyy').format(DateTime.now());
    });
  }

  void getUserData() {
    _databaseReference.child('user').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          nameController = userData!['name'];
          selectedRole = userData!['role'];
          addressController = userData!['address'];
        });
      }
    });
  }

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  // void _checkCurrentUser() async {
  //   User? user = await _auth.currentUser;
  //   setState(() {
  //     _user = user;
  //   });
  // }

  Future<void> fetchDataServis() async {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(currentDate);

    DataSnapshot snapshot = await dbRefServis
        .orderByChild('dateTime')
        .startAt(formattedDate)
        .endAt('$formattedDate\u{f8ff}')
        .get();

    if (mounted) {
      if (snapshot.exists) {
        setState(() {
          countDataServis = snapshot.children.length;
        });
      }
    }
  }

  Future<void> fetchDataPenjualan() async {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(currentDate);
    DataSnapshot snapshot = await dbRefPenjualan
        .orderByChild('dateTime')
        .startAt(formattedDate)
        .endAt('$formattedDate\u{f8ff}')
        .get();

    if (mounted) {
      if (snapshot.exists) {
        setState(() {
          countdDataPenjualan = snapshot.children.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/aplikasikasir.png',
              height: 150,
              width: 400,
            ),
            SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                height: 150,
                width: 400,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 98, 96, 238),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 71, 67, 67).withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      child: Text(
                        DateFormat.yMMMMEEEEd('initializedDateFormatting')
                            .format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 25, // Adjusted font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(top: 5),
                        child: Text(
                          'Transaksi Hari ini : ${countDataServis + countdDataPenjualan}',
                          style: const TextStyle(
                            fontSize: 25, // Adjusted font size
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 63, 63, 62),
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(top: 5),
                        child: Text(
                          'Servis : $countDataServis',
                          style: TextStyle(
                            fontSize: 25, // Adjusted font size
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 63, 63, 62),
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin:
                            EdgeInsets.only(bottom: 5), // Added bottom padding
                        child: Text(
                          'Penjualan : $countdDataPenjualan',
                          style: TextStyle(
                            fontSize: 25, // Adjusted font size
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 63, 63, 62),
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              children: [
                Container(
                  child: Text(
                    '- - Action Menu - -',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Pilih Jenis Transaksi"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text('Penjualan'),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context,
                                                        animation,
                                                        secondaryAnimation) =>
                                                    TransaksiPenjualanPage(), // Ganti dengan halaman yang sesuai
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  var begin = Offset(1.0, 0.0);
                                                  var end = Offset.zero;
                                                  var curve = Curves.ease;

                                                  var tween = Tween(
                                                          begin: begin,
                                                          end: end)
                                                      .chain(CurveTween(
                                                          curve: curve));

                                                  return SlideTransition(
                                                    position:
                                                        animation.drive(tween),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          title: Text('Servis'),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context,
                                                        animation,
                                                        secondaryAnimation) =>
                                                    ServisPage(), // Ganti dengan halaman yang sesuai
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  var begin = Offset(1.0, 0.0);
                                                  var end = Offset.zero;
                                                  var curve = Curves.ease;

                                                  var tween = Tween(
                                                          begin: begin,
                                                          end: end)
                                                      .chain(CurveTween(
                                                          curve: curve));

                                                  return SlideTransition(
                                                    position:
                                                        animation.drive(tween),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 241, 238, 147),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(1),
                              minimumSize: Size(double.infinity,
                                  150), // Tinggi tetap untuk tombol
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Menghilangkan radius
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/transaction.png',
                                  height: 80, // Tinggi gambar disesuaikan
                                  width: 80,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'TRANSAKSI',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(239, 42, 41, 41),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const ListbarangPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    var begin = const Offset(1.0, 0.0);
                                    var end = Offset.zero;
                                    var curve = Curves.ease;

                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 241, 238, 147),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(1),
                              minimumSize: Size(double.infinity,
                                  150), // Tinggi tetap untuk tombol
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Menghilangkan radius
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/listBarang.png',
                                  height: 80, // Tinggi gambar disesuaikan
                                  width: 80,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'LIST BARANG',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(239, 42, 41, 41),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      TransaksiTerimaServisPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    var begin = const Offset(1.0, 0.0);
                                    var end = Offset.zero;
                                    var curve = Curves.ease;

                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 241, 238, 147),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(1),
                              minimumSize: Size(double.infinity,
                                  150), // Lebar penuh dan tinggi tetap
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Menghilangkan radius
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/receive.png',
                                  height: 80, // Tinggi gambar disesuaikan
                                  width: 80,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'TERIMA SERVIS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(239, 42, 41, 41),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const InputPelangganPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    var begin = const Offset(1.0, 0.0);
                                    var end = Offset.zero;
                                    var curve = Curves.ease;

                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 241, 238, 147),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(1),
                              minimumSize: Size(double.infinity,
                                  150), // Lebar penuh dan tinggi tetap
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Menghilangkan radius
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/listPelanggan.png',
                                  height: 80, // Tinggi gambar disesuaikan
                                  width: 80,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'PELANGGAN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(239, 42, 41, 41),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            InkWell(
                child: UserAccountsDrawerHeader(
              accountName: Text(nameController),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/kasir.png'),
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 6, 108, 176),
              ),
            )),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 200),
                    pageBuilder: (_, __, ___) => BarangPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              leading: Icon(Icons.storage),
              title: Text('Data Barang'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 200),
                    pageBuilder: (_, __, ___) => Pelanggan(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              leading: Icon(Icons.group),
              title: Text('Data Pelanggan'),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Pilih Histori'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.receipt),
                            title: Text('Histori Terima Barang'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 200),
                                  pageBuilder: (_, __, ___) =>
                                      HistoriTerimaBarangPage(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.receipt),
                            title: Text('Histori Servis'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 200),
                                  pageBuilder: (_, __, ___) =>
                                      HistoriServisPage(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.shopping_cart),
                            title: Text('Histori Penjualan'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 200),
                                  pageBuilder: (_, __, ___) =>
                                      HistoriPenjualanPage(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              leading: Icon(Icons.history),
              title: Text('Histori'),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Pilih Laporan'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.receipt),
                            title: Text('Laporan Servis'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 200),
                                  pageBuilder: (_, __, ___) =>
                                      ServiceReportPage(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.shopping_cart),
                            title: Text('Laporan Penjualan'),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 200),
                                  pageBuilder: (_, __, ___) =>
                                      TransactionReportPage(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              leading: Icon(Icons.description),
              title: Text('Laporan'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 200),
                    pageBuilder: (_, __, ___) => AboutPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              leading: Icon(Icons.filter_b_and_w_rounded),
              title: Text('Tentang Aplikasi'),
            ),
            ListTile(
              onTap: () async {
                try {
                  final confirmed = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout'),
                      content: Text('Apakah kamu yakin ingin logout?'),
                      actions: [
                        TextButton(
                          child: Text('Tidak'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text('Ya'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // await _auth.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          showRegisterPage: () {},
                        ),
                      ),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Berhasil logout'),
                        duration: Duration(seconds: 2), // Durasi snackbar
                        behavior: SnackBarBehavior
                            .floating, // Tampilkan snackbar secara floating
                      ),
                    );
                  }
                } catch (e) {
                  print('Error during logout: $e');
                  // Handle the error appropriately (show error message, log, etc.)
                }
              },
              leading: Icon(Icons.logout),
              title: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
