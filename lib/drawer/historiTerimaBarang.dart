import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class HistoriTerimaBarangPage extends StatefulWidget {
  const HistoriTerimaBarangPage({Key? key}) : super(key: key);

  @override
  State<HistoriTerimaBarangPage> createState() =>
      _HistoriTerimaBarangPageState();
}

class _HistoriTerimaBarangPageState extends State<HistoriTerimaBarangPage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.reference().child('terimaBarang');
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _getDevices();
    _fetchData();
  }

  void _fetchData() async {
    DataSnapshot snapshot = await _dbRef.get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> results = [];
      snapshot.children.forEach((child) {
        Map<String, dynamic> data =
            Map<String, dynamic>.from(child.value as Map);
        results.add(data);
      });

      setState(() {
        _data = results;
        _filteredData = results;
        _filterData();
      });
    }
  }

  void _filterData() {
    String searchText = _searchController.text.trim().toLowerCase();
    setState(() {
      if (searchText.isNotEmpty) {
        _filteredData = _data.where((item) {
          String idServis = item['idServis']?.toString().toLowerCase() ?? '';
          String namaPelanggan =
              item['namaPelanggan']?.toString().toLowerCase() ?? '';
          return idServis.contains(searchText) ||
              namaPelanggan.contains(searchText);
        }).toList();
      } else {
        _filteredData = _data;
      }
    });
  }

  Widget _buildListItem(Map<String, dynamic> transaksi) {
    String idTransaksi = transaksi['idServis'] ?? '';
    String dateTime = transaksi['dateTimeTerima'] ?? '';
    String kodePelanggan = transaksi['kodePelanggan'] ?? '';
    String namaPelanggan = transaksi['namaPelanggan'] ?? '';
    String alamatPelanggan = transaksi['alamat'] ?? '';
    String noTelepon = transaksi['noHp'] ?? '';
    String keluhan = transaksi['keluhan'] ?? '';
    bool isDone = transaksi['isDone'] ?? false;
    String status = isDone ? "Sudah selesai" : "Belum selesai";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text('ID Servis: $idTransaksi',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal dan Waktu: $dateTime'),
                Text('Kode Pelanggan: $kodePelanggan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Nama Pelanggan: $namaPelanggan'),
                Text('Alamat: $alamatPelanggan'),
                Text('No Telepon: $noTelepon'),
                Text('Keluhan: $keluhan'),
                Text('Status: $status'),
              ],
            ),
          ),
          Positioned(
            bottom: 8.0,
            right: 8.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Konfirmasi'),
                          content: Text('Hapus data transaksi ini?'),
                          actions: [
                            TextButton(
                              child: Text('Batal'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Hapus'),
                              onPressed: () {
                                _dbRef.child(idTransaksi).remove();
                                Navigator.of(context).pop();
                                _fetchData();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.print),
                  onPressed: () {
                    _selectPrinter(transaksi);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Data tidak ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Pastikan ejaan dengan benar',
            style: TextStyle(fontSize: 14, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  void _getDevices() async {
    _devices = await _printer.getBondedDevices();
    setState(() {});
  }

  void _selectPrinter(Map<String, dynamic> transaksi) async {
    if (_devices.isEmpty) {
      return;
    }

    final selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Printer'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _devices.map((device) {
                return ListTile(
                  onTap: () {
                    Navigator.of(context).pop(device);
                  },
                  leading: const Icon(Icons.print),
                  title: Text(device.name.toString()),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedDevice != null) {
      setState(() {
        _selectedDevice = selectedDevice;
      });

      _printReceipt(selectedDevice, transaksi);
    }
  }

  void _printReceipt(
      BluetoothDevice selectedDevice, Map<String, dynamic> transaksi) {
    try {
      _printer.connect(selectedDevice).then((_) {
        _printer.paperCut();
        _printer.printNewLine();
        _printer.printCustom('Pelita Elektronik Ciguling', 3, 1);
        _printer.printCustom('Penjualan & Servis', 0, 1);
        _printer.printCustom('Jl. Raya Cilopadang RT 002/004', 0, 1);
        _printer.printCustom('Cilopadang, Majenang', 0, 1);
        _printer.printCustom('53257 Cilacap, Jawa Tengah', 0, 1);
        _printer.printCustom('0812-1566-8669', 1, 1);
        _printer.printNewLine();
        _printer.printCustom('ID Servis: ${transaksi['idServis']}', 1, 0);
        _printer.printCustom('Date/Time: ${transaksi['dateTimeTerima']}', 1, 0);
        _printer.printCustom('--------------------------------', 0, 0);
        _printer.printCustom(
            'Kode Pelanggan: ${transaksi['kodePelanggan']}', 1, 0);
        _printer.printCustom(
            'Nama Pelanggan: ${transaksi['namaPelanggan']}', 1, 0);
        _printer.printCustom('--------------------------------', 0, 0);
        _printer.printCustom('Keluhan: ${transaksi['keluhan']}', 1, 0);
        _printer.printCustom(
          'Status: ${transaksi['isDone'] ? "Sudah selesai" : "Belum selesai"}',
          1,
          0,
        );
        _printer.printNewLine();
        _printer.printCustom('--------------------------------', 0, 0);
        _printer.printNewLine();
        _printer.printCustom('Simpan Kuitansi', 2, 1);
        _printer.printCustom('Saat pengambilan barang', 1, 1);
        _printer.printCustom('wajib membawa ini', 1, 1);
        _printer.printNewLine();
        _printer.paperCut();
      });
    } catch (e) {
      print("Error printing receipt: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
                context); // Adjust navigation based on your app structure
          },
        ),
        title: Text(
          'Histori Terima Barang',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Total Transaksi: ${_filteredData.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterData();
              },
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Cari ID Servis atau Nama Pelanggan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterData();
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _filteredData.isEmpty
                ? _buildNoDataWidget()
                : ListView.builder(
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      return _buildListItem(_filteredData[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
