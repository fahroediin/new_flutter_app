import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UpdateRecord extends StatefulWidget {
  const UpdateRecord({Key? key, required this.barangKey}) : super(key: key);

  final String barangKey;

  @override
  State<UpdateRecord> createState() => _UpdateRecordState();
}

class _UpdateRecordState extends State<UpdateRecord> {
  late DatabaseReference dbRef;

  late TextEditingController namaBarangController;
  late TextEditingController hargaBarangController;
  late TextEditingController stokBarangController;

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.reference().child('daftarBarang');
    getDaftarbarang();

    namaBarangController = TextEditingController();
    hargaBarangController = TextEditingController();
    stokBarangController = TextEditingController();
  }

  void getDaftarbarang() async {
    DataSnapshot snapshot = await dbRef.child(widget.barangKey).get();
    Map<dynamic, dynamic> daftarbarang =
        snapshot.value as Map<dynamic, dynamic>;

    setState(() {
      namaBarangController.text = daftarbarang['namaBarang'];
      hargaBarangController.text = daftarbarang['hargaBarang'].toString();
      stokBarangController.text = daftarbarang['stokBarang'].toString();
    });
  }

  @override
  void dispose() {
    namaBarangController.dispose();
    hargaBarangController.dispose();
    stokBarangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Barang'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextField(
                  controller: namaBarangController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nama Barang',
                    hintText: 'Masukkan Nama Barang',
                  ),
                  textCapitalization: TextCapitalization
                      .words, // Mengubah hanya huruf pertama pada setiap kata yang kapital
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: hargaBarangController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Harga',
                    hintText: 'Masukkan Harga barang',
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: stokBarangController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Stok',
                    hintText: 'Masukkan Stok barang',
                  ),
                ),
                const SizedBox(height: 30),
                MaterialButton(
                  onPressed: () {
                    if (namaBarangController.text.isEmpty ||
                        hargaBarangController.text.isEmpty ||
                        stokBarangController.text.isEmpty) {
                      _showSnackBar('Mohon lengkapi semua field');
                    } else {
                      Map<String, dynamic> barang = {
                        'namaBarang': namaBarangController.text,
                        'hargaBarang': int.parse(hargaBarangController.text),
                        'stokBarang': int.parse(stokBarangController.text),
                      };

                      dbRef.child(widget.barangKey).update(barang).then((_) {
                        _showSnackBar('Data berhasil diperbarui');
                        Navigator.pop(
                            context, true); // true berarti berhasil update
                      }).catchError((error) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: Text('Failed to update record: $error'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      });
                    }
                  },
                  child: const Text('Update Data'),
                  color: const Color.fromARGB(255, 6, 108, 176),
                  textColor: Colors.white,
                  minWidth: 500,
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
