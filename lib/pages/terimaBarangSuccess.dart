import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:new_flutter_app/pages/receiptTerimaBarang.dart';
import 'package:new_flutter_app/pages/terimaBarang.dart';

class TerimaBarangSuccess extends StatefulWidget {
  final String idTransaksi;
  final String formattedDateTime;
  final String kodePelanggan;
  final String namaPelanggan;
  final String keluhan;
  final String namaBarangServis;
  final String alamatPelanggan;
  final String noHpPelanggan;
  final bool isDone;

  TerimaBarangSuccess(
      {required this.idTransaksi,
      required this.formattedDateTime,
      required this.kodePelanggan,
      required this.namaPelanggan,
      required this.keluhan,
      required this.namaBarangServis,
      required this.alamatPelanggan,
      required this.noHpPelanggan,
      this.isDone = false});

  @override
  _TerimaBarangSuccessState createState() => _TerimaBarangSuccessState();
}

class _TerimaBarangSuccessState extends State<TerimaBarangSuccess> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    getDevices();
  }

  void getDevices() async {
    devices = await printer.getBondedDevices();
    setState(() {});
  }

  void _selectPrinter() async {
    if (devices.isEmpty) {
      return;
    }

    final selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Printer'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.map((device) {
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
        this.selectedDevice = selectedDevice;
      });

      printReceipt();
    }
  }

  void printReceipt() {
    if (selectedDevice != null) {
      try {
        printer.connect(selectedDevice!).then((_) {
          printer.paperCut();
          printer.printNewLine();
          printer.printCustom(
            'Pelita Elektronik Ciguling',
            3,
            1,
          );
          printer.printCustom(
            'Penjualan & Servis',
            0,
            1,
          );
          printer.printCustom(
            'Jl. Raya Cilopadang RT 002/004',
            0,
            1,
          );
          printer.printCustom(
            'Cilopadang, Majenang',
            0,
            1,
          );
          printer.printCustom(
            '53257 Cilacap, Jawa Tengah',
            0,
            1,
          );
          printer.printCustom(
            '0812-1566-8669',
            1,
            1,
          );
          printer.printNewLine();
          printer.printCustom('ID Servis: ${widget.idTransaksi}', 1, 0);
          printer.printCustom('Date/Time: ${widget.formattedDateTime}', 1, 0);
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom('Kode Pelanggan: ${widget.kodePelanggan}', 1, 0);
          printer.printCustom('Nama Pelanggan: ${widget.namaPelanggan}', 1, 0);
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom('Nama Barang: ${widget.namaBarangServis}', 1, 0);
          printer.printCustom('Keluhan: ${widget.keluhan}', 1, 0);
          printer.printNewLine();
          printer.printCustom('--------------------------------', 0, 0);
          printer.printNewLine();
          printer.printCustom('Simpan Kuitansi', 2, 1);
          printer.printCustom('Saat pengambilan barang', 1, 1);
          printer.printCustom('wajib membawa ini', 1, 1);
          printer.printNewLine();
          printer.paperCut();

          // Menambahkan jeda 5 detik sebelum memutuskan koneksi
          Future.delayed(Duration(seconds: 5), () {
            printer.disconnect().then((_) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Cetak Kuitansi'),
                    content: Text('Berhasil mencetak kuitansi'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            });
          });
        });
      } on PlatformException catch (e) {
        print(e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/success.png',
              width: 200,
            ),
            SizedBox(height: 20),
            Text(
              'Selamat!',
              style: TextStyle(
                fontSize: 30,
                color: Color.fromARGB(255, 102, 103, 102),
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Transaksi Berhasil!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransaksiTerimaServisPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 108, 176),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Transaksi Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                onPressed: _selectPrinter,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 5),
                    Text(
                      'Print Receipt',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiptTerimaBarang(
                      transactionData: {
                        'idServis': widget.idTransaksi,
                        'dateTimeTerima': widget.formattedDateTime,
                        'kodePelanggan': widget.kodePelanggan,
                        'namaPelanggan': widget.namaPelanggan,
                        'keluhan': widget.keluhan,
                        'namaBarangServis': widget.namaBarangServis,
                        'alamatPelanggan': widget.alamatPelanggan,
                        'noHpPelanggan': widget.noHpPelanggan,
                        'isDone': widget.isDone
                      },
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Center(
                      child: Text(
                        'Lihat Kuitansi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
