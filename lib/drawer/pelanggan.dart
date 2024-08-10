import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'update_pelanggan.dart';

class Pelanggan extends StatefulWidget {
  const Pelanggan({Key? key}) : super(key: key);

  @override
  _PelangganState createState() => _PelangganState();
}

class _PelangganState extends State<Pelanggan> {
  Query dbRef = FirebaseDatabase.instance.reference().child('daftarPelanggan');
  int itemCount = 0;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool hasData = true;
  List<Map> allData = [];
  List<Map> filteredData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    DataSnapshot snapshot = await dbRef.get();
    if (snapshot.exists) {
      List<Map> tempList = [];
      snapshot.children.forEach((child) {
        Map pelanggan = child.value as Map;
        pelanggan['key'] = child.key;
        tempList.add(pelanggan);
      });
      setState(() {
        allData = tempList;
        filteredData = tempList;
        itemCount = tempList.length;
        hasData = tempList.isNotEmpty;
      });
    } else {
      setState(() {
        itemCount = 0;
        allData = [];
        filteredData = [];
        hasData = false;
      });
    }
  }

  void searchList(String query) {
    if (query.isNotEmpty) {
      setState(() {
        isSearching = true;
        filteredData = allData
            .where((item) =>
                item['kodePelanggan']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                item['namaPelanggan']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
        hasData = filteredData.isNotEmpty;
      });
    } else {
      setState(() {
        isSearching = false;
        filteredData = allData;
        hasData = allData.isNotEmpty;
      });
    }
  }

  void deletePelanggan(String key) {
    FirebaseDatabase.instance
        .reference()
        .child('daftarPelanggan')
        .child(key)
        .remove()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data pelanggan berhasil dihapus'),
          duration: Duration(seconds: 2),
        ),
      );
      fetchData();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    });
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
                transitionDuration: Duration(milliseconds: 200),
                pageBuilder: (_, __, ___) => HomePage(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        title: Text(
          'Data Pelanggan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total Pelanggan : $itemCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        searchList(value);
                        searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: searchController.text.length),
                        );
                      },
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Cari Kode/Nama Pelanggan',
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
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: hasData
                  ? ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        Map pelanggan = filteredData[index];
                        return Column(
                          children: [
                            buildListItem(
                              daftarPelanggan: pelanggan,
                              kodePelanggan: pelanggan['kodePelanggan'],
                              namaPelanggan: pelanggan['namaPelanggan'],
                              alamat: pelanggan['alamat'],
                              noHp: pelanggan['noHp'],
                              snapshot: null,
                            ),
                            SizedBox(height: 8),
                            Divider(color: Colors.grey[400]),
                          ],
                        );
                      },
                    )
                  : buildNoDataWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListItem({
    required Map daftarPelanggan,
    required String kodePelanggan,
    required String namaPelanggan,
    required String alamat,
    required String noHp,
    required DataSnapshot? snapshot,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      height: 210,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 241, 238, 147),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kode Pelanggan: $kodePelanggan',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nama Pelanggan: $namaPelanggan',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Alamat: $alamat',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Nomor HP: $noHp',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpdatePelanggan(
                        pelangganKey: daftarPelanggan['key'],
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      fetchData(); // Refresh data jika berhasil diperbarui
                    }
                  });
                },
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Konfirmasi'),
                        content: Text('Hapus data pelanggan?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              deletePelanggan(daftarPelanggan['key']);
                              Navigator.of(context).pop();
                            },
                            child: Text('Yes'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
