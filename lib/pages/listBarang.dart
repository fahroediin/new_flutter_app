import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter_app/pages/home_page.dart';

class ListbarangPage extends StatefulWidget {
  const ListbarangPage({Key? key}) : super(key: key);

  @override
  State<ListbarangPage> createState() => _ListbarangPageState();
}

class _ListbarangPageState extends State<ListbarangPage> {
  Query dbRef = FirebaseDatabase.instance.reference().child('daftarBarang');
  late DatabaseReference _itemsRef;
  String _formattedDateTime = '';
  List<Map> barangList = [];
  List<Map> filteredbarangList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemsRef = FirebaseDatabase.instance.reference().child('daftarBarang');
    _itemsRef.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          barangList = List<Map>.from(
              (snapshot.value as Map<dynamic, dynamic>).values.toList());
          barangList.sort((a, b) => a['namaBarang'].compareTo(b['namaBarang']));
          filteredbarangList = barangList;
        });
      }
    });
  }

  @override
  void dispose() {
    _itemsRef.onValue.drain(); // Hentikan listener saat widget dihancurkan
    super.dispose();
  }

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void searchList(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredbarangList = barangList;
      } else {
        filteredbarangList = barangList.where((barang) {
          String namaBarang = barang['namaBarang'].toString().toLowerCase();
          String specbarang = barang['specbarang'].toString().toLowerCase();
          return namaBarang.contains(query.toLowerCase()) ||
              specbarang.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget buildNoDataWidget() {
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
              ),
            );
          },
        ),
        title: Text(
          'Daftar Barang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (value) {
                searchList(value);
              },
              decoration: InputDecoration(
                labelText: 'Cari Nama Barang',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchList('');
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: filteredbarangList.isEmpty
                  ? buildNoDataWidget()
                  : ListView.builder(
                      itemCount: filteredbarangList.length,
                      itemBuilder: (context, index) {
                        Map barang = filteredbarangList[index];
                        return Column(
                          children: [
                            listItem(barang: barang),
                            SizedBox(height: 8),
                            Divider(color: Colors.grey[400]),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget listItem({required Map barang}) {
    int stokBarang = barang['stokBarang'];
    Color fontColor = stokBarang <= 5 ? Colors.red : Colors.black;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${barang['namaBarang']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${barang['idBarang']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Harga: Rp ${formatCurrency(barang['hargaBarang'])}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'Stok: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${barang['stokBarang']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: fontColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stokBarang <= 5)
                    Text(
                      'Harap Restock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: fontColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
