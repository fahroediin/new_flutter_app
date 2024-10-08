import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class TransactionReportPage extends StatefulWidget {
  @override
  _TransactionReportPageState createState() => _TransactionReportPageState();
}

class _TransactionReportPageState extends State<TransactionReportPage> {
  List<String> monthList = [];
  String selectedMonth = '';

  DatabaseReference dbRefPenjualan =
      FirebaseDatabase.instance.reference().child('transaksiPenjualan');
  int countDataPenjualan = 0;
  int jumlahTransaksi = 0;
  int jumlahItemTerjual = 0;
  int jumlahTotalPendapatan = 0;
  int totalDiskon = 0;
  int totalPendapatanBersih = 0;

  List<barangRanking> barangRankings = [];

  Future<void> fetchDataPenjualan() async {
    String formattedMonth = DateFormat('MM/yyyy')
        .format(DateFormat('MMMM yyyy', 'id_ID').parse(selectedMonth));
    DateTime firstDayOfMonth = DateTime(int.parse(formattedMonth.split('/')[1]),
        int.parse(formattedMonth.split('/')[0]), 1);
    DateTime lastDayOfMonth = DateTime(int.parse(formattedMonth.split('/')[1]),
        int.parse(formattedMonth.split('/')[0]) + 1, 0);
    String formattedFirstDayOfMonth =
        DateFormat('dd/MM/yyyy').format(firstDayOfMonth);
    String formattedLastDayOfMonth =
        DateFormat('dd/MM/yyyy').format(lastDayOfMonth);
    DataSnapshot snapshot =
        await dbRefPenjualan.orderByChild('bulan').equalTo(selectedMonth).get();

    if (mounted) {
      if (snapshot.value != null) {
        int totalJumlahItemTerjual = 0;
        int totalHarga = 0;
        int totalDiskonPenjualan = 0;

        // Reset sparepart rankings
        barangRankings = [];

        Map<dynamic, dynamic>? snapshotValue =
            snapshot.value as Map<dynamic, dynamic>?;
        snapshotValue?.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            int? jumlahItem = int.tryParse(value['jumlahItem'].toString());
            int? hargaAkhir = int.tryParse(value['hargaAkhir'].toString());
            int? diskon = int.tryParse(value['totalDiskon'].toString());

            totalJumlahItemTerjual += jumlahItem ?? 0;
            totalHarga += hargaAkhir ?? 0;
            totalDiskonPenjualan += diskon ?? 0;

            List<dynamic>? items = value['items'] as List<dynamic>?;
            if (items != null) {
              items.forEach((item) {
                String idBarang = item['idBarang'].toString();
                String namaBarang = item['namaBarang'].toString();

                bool sparepartExist = false;
                for (int i = 0; i < barangRankings.length; i++) {
                  if (barangRankings[i].idBarang == idBarang) {
                    sparepartExist = true;
                    barangRankings[i].jumlah += jumlahItem ?? 0;
                    break;
                  }
                }

                if (!sparepartExist) {
                  barangRankings.add(barangRanking(
                    idBarang: idBarang,
                    namaBarang: namaBarang,
                    jumlah: jumlahItem ?? 0,
                  ));
                }
              });
            }
          }
        });

        barangRankings.sort((a, b) => b.jumlah.compareTo(a.jumlah));

        setState(() {
          jumlahTransaksi = snapshot.children.length;
          jumlahItemTerjual = totalJumlahItemTerjual;
          jumlahTotalPendapatan = totalHarga;
          totalDiskon = totalDiskonPenjualan;
          totalPendapatanBersih = totalHarga - totalDiskonPenjualan;
        });
      } else {
        setState(() {
          barangRankings = [];
        });
      }
    }
  }

  Future<void> initializeMonthList() async {
    DataSnapshot snapshot = await dbRefPenjualan.get();
    if (snapshot.value != null) {
      Set<String> uniqueMonths = {};
      Map<dynamic, dynamic>? snapshotValue =
          snapshot.value as Map<dynamic, dynamic>?;
      snapshotValue?.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          String? bulan = value['bulan'].toString();
          if (bulan != null) {
            uniqueMonths.add(bulan);
          }
        }
      });

      setState(() {
        monthList = uniqueMonths.toList();
        monthList.sort((a, b) {
          DateTime aDate = DateFormat('MMMM yyyy', 'id_ID').parse(a);
          DateTime bDate = DateFormat('MMMM yyyy', 'id_ID').parse(b);
          return bDate.compareTo(aDate);
        });

        if (monthList.isNotEmpty) {
          selectedMonth = monthList[0];
        }
      });
    }
  }

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    initializeMonthList().then((_) {
      fetchDataPenjualan();
    });
  }

  Future<void> savePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Laporan Penjualan'),
            ),
            pw.Header(
              level: 1,
              child: pw.Text('Bulan: $selectedMonth'),
            ),
            pw.Paragraph(
              text: 'Jumlah Transaksi: ${jumlahTransaksi.toString()}',
            ),
            pw.Paragraph(
              text: 'Jumlah Item Terjual: ${jumlahItemTerjual.toString()}',
            ),
            pw.Paragraph(
              text:
                  'Total Pendapatan Penjualan: Rp ${formatCurrency(jumlahTotalPendapatan)}',
            ),
            pw.Paragraph(
              text: 'Total Diskon: Rp ${formatCurrency(totalDiskon)}',
            ),
            pw.Paragraph(
              text:
                  'Total Pendapatan Bersih: Rp ${formatCurrency(totalPendapatanBersih)}',
            ),
          ],
        ),
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/transaction_report.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the saved PDF file
    OpenFile.open(file.path);

    // Show a SnackBar to inform the user that the PDF has been saved.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan penjualan berhasil disimpan.'),
        behavior: SnackBarBehavior.floating, // Set behavior to floating
        duration: Duration(seconds: 3), // Set duration to 3 seconds
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 6, 108, 176),
        title: Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: savePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Laporan Bulan:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedMonth,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedMonth = newValue!;
                              fetchDataPenjualan();
                            });
                          },
                          items: monthList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(fontSize: 18),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bulan',
                                style: TextStyle(fontSize: 18),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  selectedMonth,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jumlah Transaksi',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 18),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  jumlahTransaksi.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jumlah Item Terjual',
                                style: TextStyle(fontSize: 18),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  jumlahItemTerjual.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pendapatan Penjualan',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Rp ' + formatCurrency(jumlahTotalPendapatan),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Diskon',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Rp ' + formatCurrency(totalDiskon),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pendapatan Bersih',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Rp ' + formatCurrency(totalPendapatanBersih),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class barangRanking {
  final String idBarang;
  final String namaBarang;
  int jumlah;

  barangRanking({
    required this.idBarang,
    required this.namaBarang,
    required this.jumlah,
  });
}
