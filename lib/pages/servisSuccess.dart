import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'package:new_flutter_app/pages/receiptService.dart';
import 'package:new_flutter_app/pages/servis.dart';

class ServisSuccessPage extends StatefulWidget {
  final String idServis;
  final String dateTime;
  final String kerusakan;
  final String catatan;
  final List<Map<String, dynamic>> items;
  final double diskon;
  final double bayar;
  final double biayaServis;
  final double kembalian;
  final double hargaAkhir;
  final double totalHarga;
  final String namaPelanggan; // Added
  final String kodePelanggan; // Added

  ServisSuccessPage({
    required this.idServis,
    required this.dateTime,
    required this.kerusakan,
    required this.catatan,
    required this.items,
    required this.diskon,
    required this.bayar,
    required this.kembalian,
    required this.biayaServis,
    required this.hargaAkhir,
    required this.totalHarga,
    required this.namaPelanggan,
    required this.kodePelanggan,
  });

  @override
  _ServisSuccessPageState createState() => _ServisSuccessPageState();
}

class _ServisSuccessPageState extends State<ServisSuccessPage> {
  final _formKey = GlobalKey<FormState>();
  String? _idServis;
  String? _tanggalTransaksi;
  String? _namaPembeli;
  double _bayar = 0;
  double _kembalian = 0;
  final List<Map<String, dynamic>> _items = [];
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    getDevices();
    _items.addAll(widget.items);
  }

  void getDevices() async {
    devices = await printer.getBondedDevices();
    setState(() {});
  }

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void _selectPrinter() async {
    if (devices.isEmpty) {
      return;
    }

    final selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih Printer'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.map((device) {
                return ListTile(
                  onTap: () {
                    Navigator.of(context).pop(device);
                  },
                  leading: Icon(Icons.print),
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
          printer.printCustom('ID Servis: ${widget.idServis}', 1, 0);
          printer.printCustom('Date/Time: ${widget.dateTime}', 1, 0);
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom('Kode Pelanggan: ${widget.kodePelanggan}', 1, 0);
          printer.printCustom('Nama Pelanggan: ${widget.namaPelanggan}', 1, 0);
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom('Keluhan: ${widget.kerusakan}', 1, 0);
          printer.printCustom('Catatan: ${widget.catatan}', 1, 0);
          printer.printNewLine();
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom('Items               Qty   Price', 0, 0);
          for (var item in _items) {
            String itemName = item['namaBarang'];
            int quantity = item['jumlahBarang'];
            int price = item['hargaBarang'];

            // Wrap nama sparepart if it exceeds 18 characters
            List<String> wrappedItemName = wrapText(itemName, 18);

            // Pad the strings to align the columns
            String paddedItemName = wrappedItemName[0].padRight(18);
            String paddedQuantity = quantity.toString().padLeft(4);
            String paddedPrice = formatCurrency(price).padLeft(9);

            // Create the final formatted line
            String formattedLine = '$paddedItemName$paddedQuantity$paddedPrice';

            printer.printCustom(formattedLine, 1, 0);

            // Print additional wrapped lines, if any
            if (wrappedItemName.length > 1) {
              for (int i = 1; i < wrappedItemName.length; i++) {
                printer.printCustom(wrappedItemName[i].padRight(18), 1, 0);
              }
            }
          }
          printer.printNewLine();
          printer.printCustom('--------------------------------', 0, 0);
          double totalDiskon = (widget.totalHarga * widget.diskon) / 100;

          String harga = 'Rp ${widget.totalHarga.toStringAsFixed(0)}';
          String diskon = '${widget.diskon.toStringAsFixed(0)}%';
          int jumlahItem = 0;

          for (var item in _items) {
            int quantity = item['jumlahBarang'];
            jumlahItem += quantity;
          }
          String potonganHarga = 'Total Diskon'.padRight(20) +
              'Rp ${formatCurrency(totalDiskon.toInt())}';

          String totalItem = jumlahItem.toString();
          String formattedTotalItem = totalItem.padRight(3);

          String totalItemLabel = 'Total Item';
          String totalItemColumn = totalItemLabel.padRight(15);
          String hargaColumn =
              'Rp ${formatCurrency(widget.totalHarga.toInt())}'.padRight(2);

          printer.printCustom(
              '$totalItemColumn$formattedTotalItem  $hargaColumn', 1, 0);

          printer.printCustom('Diskon'.padRight(20) + diskon, 1, 0);
          printer.printCustom(potonganHarga, 1, 0);
          printer.printCustom(
              'Total '.padRight(20) +
                  'Rp ${formatCurrency(widget.hargaAkhir.toInt())}',
              1,
              0);
          printer.printCustom(
              'Biaya Servis '.padRight(20) +
                  'Rp ${formatCurrency(widget.biayaServis.toInt())}',
              1,
              0);
          double total = widget.hargaAkhir + widget.biayaServis;
          printer.printCustom('--------------------------------', 0, 0);
          printer.printCustom(
              'Total '.padRight(20) + 'Rp ${formatCurrency(total.toInt())}',
              1,
              0);
          printer.printCustom(
              'Bayar '.padRight(20) +
                  'Rp ${formatCurrency(widget.bayar.toInt())}',
              1,
              0);
          printer.printCustom(
              'Kembalian '.padRight(20) +
                  'Rp ${formatCurrency(widget.kembalian.toInt())}',
              1,
              0);
          printer.printNewLine();
          printer.printCustom('Terima Kasih', 2, 1);
          printer.printCustom('Atas Kunjungan Anda', 1, 1);
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

  List<String> wrapText(String text, int maxLength) {
    List<String> lines = [];
    while (text.length > maxLength) {
      int spaceIndex = text.lastIndexOf(' ', maxLength);
      if (spaceIndex == -1) {
        spaceIndex = maxLength;
      }
      lines.add(text.substring(0, spaceIndex));
      text = text.substring(spaceIndex + 1);
    }
    lines.add(text);
    return lines;
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kembalian',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Rp ${formatCurrency(widget.kembalian.toInt())}',
                      style: TextStyle(fontSize: 22),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
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
                      builder: (context) => const HomePage(),
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
                      'Home',
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
                    builder: (context) => ReceiptServisPage(),
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
