import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class ReceiptTerimaBarang extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  ReceiptTerimaBarang({required this.transactionData});

  _ReceiptTerimaBarangState createState() => _ReceiptTerimaBarangState();
}

class _ReceiptTerimaBarangState extends State<ReceiptTerimaBarang> {
  late String _pdfPath;

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  Future<void> savePdf(
      BuildContext context, Map<String, dynamic> transactionData) async {
    final pdf = pw.Document();

    // Build the PDF content
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ID Servis: ${transactionData['idServis']}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Tanggal dan Waktu: ${transactionData['dateTimeTerima']}',
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Kode Pelanggan: ${transactionData['kodePelanggan']}',
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Nama Pelanggan: ${transactionData['namaPelanggan']}',
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Nama Barang: ${transactionData['namaBarangServis']}',
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Keluhan: ${transactionData['keluhan']}',
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Status: ${transactionData['isDone'] ? 'Sudah selesai' : 'Belum selesai'}',
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save the PDF to a temporary file
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_terima-barang.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the saved PDF file
    OpenFile.open(file.path);

    // Show a SnackBar to inform the user that the PDF has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('The receipt PDF is saved successfully.'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionData = widget.transactionData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Servis: ${transactionData['idServis']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tanggal dan Waktu: ${transactionData['dateTimeTerima']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(),
                      const SizedBox(height: 10),
                      Text(
                        'Kode Pelanggan: ${transactionData['kodePelanggan']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nama Pelanggan: ${transactionData['namaPelanggan']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(),
                      const SizedBox(height: 10),
                      Text(
                        'Nama Barang: ${transactionData['namaBarangServis']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Keluhan: ${transactionData['keluhan']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await savePdf(context, transactionData);
        },
        child: Icon(Icons.save),
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
      ),
    );
  }
}
