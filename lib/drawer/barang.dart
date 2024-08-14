import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter_app/drawer/update_barang.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'insert_barang.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({Key? key}) : super(key: key);

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  Query dbRef = FirebaseDatabase.instance.reference().child('daftarBarang');
  int itemCount = 0;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool hasData = true;
  List<Map> allData = [];
  List<Map> filteredData = [];

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void searchList(String query) {
    if (query.isNotEmpty) {
      setState(() {
        isSearching = true;
        filteredData = allData
            .where((item) => item['namaBarang']
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

  Future<void> fetchData() async {
    DataSnapshot snapshot = await dbRef.get();
    if (snapshot.value != null) {
      List<Map> tempList = [];
      snapshot.children.forEach((child) {
        Map barang = child.value as Map;
        barang['key'] = child.key;
        tempList.add(barang);
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

  void deleteBarang(String key) {
    FirebaseDatabase.instance
        .reference()
        .child('daftarBarang')
        .child(key)
        .remove()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data barang berhasil dihapus'),
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
  void initState() {
    super.initState();
    fetchData();
    dbRef.onValue.listen((event) {
      fetchData();
    });
  }

  Widget listItem({required Map barang}) {
    Color stockColor = Colors.black;
    String stockText = 'Stok: ${barang['stokBarang']}';

    if (barang['stokBarang'] <= 5) {
      stockColor = Colors.red;
      stockText = 'Stok: ${barang['stokBarang']}  !! Harap restock !!';
    }

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      height: 220, // Adjusted height to fit new content
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
            'ID: ${barang['idBarang']}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nama: ${barang['namaBarang']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Kategori: ${barang['kategori'] ?? 'Belum Ditentukan'}', // Display category
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Harga: Rp ' + formatCurrency(barang['hargaBarang']),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            stockText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: stockColor,
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
                              builder: (_) =>
                                  UpdateRecord(barangKey: barang['key'])))
                      .then((value) {
                    if (value != null && value == true) {
                      fetchData(); // Reload data after successful update
                    }
                  });
                },
                child: Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Konfirmasi'),
                        content: const Text('Hapus data barang?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteBarang(barang['key']);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Yes'),
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

  Widget _floatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => InputbarangPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: Icon(Icons.add),
      backgroundColor: Color.fromARGB(255, 6, 108, 176),
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
          'Data Barang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total barang : $itemCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: searchController,
              onChanged: (value) {
                searchList(value);
              },
              textCapitalization: TextCapitalization.words,
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
            SizedBox(height: 10),
            Expanded(
              child: hasData
                  ? ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        Map barang = filteredData[index];
                        return Column(
                          children: [
                            listItem(barang: barang),
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
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
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
