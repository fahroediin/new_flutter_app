import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:open_file/open_file.dart';

class ServiceReportPage extends StatefulWidget {
  @override
  _ServiceReportPageState createState() => _ServiceReportPageState();
}

class _ServiceReportPageState extends State<ServiceReportPage> {
  List<String> monthList = [];
  String selectedMonth = '';
  int selectedYear = DateTime.now().year;
  Query dbRefServis =
      FirebaseDatabase.instance.reference().child('transaksiServis');
  int countDataServis = 0;
  int jumlahServis = 0;
  int jumlahTotalPendapatan = 0;
  int totalAkhir = 0;
  int totalDiskon = 0;
  int hargaAkhir = 0;
  int totalPendapatanServis = 0;
  int totalBarang = 0;
  int totalPendapatanBarang = 0;
  List<Map<String, dynamic>> pelangganRanking = [];
  Map<String, String> namaPelangganMap = {};
  Map<String, int> jumlahMap = {};

  Future<void> fetchDataServis() async {
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
        await dbRefServis.orderByChild('bulan').equalTo(selectedMonth).get();

    if (mounted) {
      if (snapshot.exists) {
        int count = (snapshot.value as Map<dynamic, dynamic>).length;
        int totalBiayaServis = 0;
        int totalDiskonServis = 0;
        int totalHargaAkhir = 0;
        int totalPendapatan = 0;
        int totalItems = 0; // Total Barang
        int totalHargaBarang = 0;
        Map<String, int> kodePelangganCountMap = {};

        (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
          totalBiayaServis += (value['biayaServis'] ?? 0) as int;
          totalDiskonServis += (value['totalDiskon'] ?? 0) as int;
          totalHargaAkhir += (value['hargaAkhir'] ?? 0) as int;
          totalPendapatan +=
              (value['totalAkhir'] ?? 0) as int; // Total Pendapatan Servis
          totalItems += (value['jumlahItem'] ?? 0) as int; // Total Barang
          totalHargaBarang += (value['totalHargaBarang'] ?? 0) as int;
          String kodePelanggan = value['kodePelanggan'];
          String namaPelanggan = value['namaPelanggan'];
          int jumlah = value['jumlah'] ?? 0;

          kodePelangganCountMap[kodePelanggan] =
              (kodePelangganCountMap[kodePelanggan] ?? 0) + 1;

          namaPelangganMap[kodePelanggan] = namaPelanggan;
        });

        List<MapEntry<String, int>> kodePelangganCountList =
            kodePelangganCountMap.entries.toList();
        kodePelangganCountList.sort((a, b) => b.value.compareTo(a.value));
        pelangganRanking = kodePelangganCountList
            .take(10)
            .map((entry) => {
                  'kodePelanggan': entry.key,
                  'jumlah': entry.value.toString(),
                  'nama': namaPelangganMap[entry.key] ?? '',
                })
            .toList();

        setState(() {
          countDataServis = count;
          jumlahServis = countDataServis;
          jumlahTotalPendapatan = totalBiayaServis;
          totalAkhir = totalBiayaServis;
          totalDiskon = totalDiskonServis;
          hargaAkhir = totalHargaAkhir;
          totalPendapatanServis =
              totalPendapatan; // Set Total Pendapatan Servis
          totalBarang = totalItems; // Set Total Barang
          totalPendapatanBarang =
              totalHargaBarang; // Set Total Pendapatan Barang
        });
      }
    }
  }

  Future<List<String>> getDistinctMonths() async {
    DataSnapshot snapshot = await dbRefServis.orderByChild('bulan').get();
    List<String> distinctMonths = [];

    if (snapshot.exists) {
      (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
        if (value['bulan'] != null) {
          String month = value['bulan'];
          if (!distinctMonths.contains(month)) {
            distinctMonths.add(month);
          }
        }
      });
    }

    return distinctMonths;
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
      fetchDataServis();
    });
  }

  Future<void> initializeMonthList() async {
    DataSnapshot snapshot = await dbRefServis.get();
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

  Future<void> savePdf() async {
    final pdf = pdfWidgets.Document();

    pdf.addPage(
      pdfWidgets.Page(
        build: (context) => pdfWidgets.Column(
          children: [
            pdfWidgets.Header(
              level: 0,
              child: pdfWidgets.Text('Laporan Servis'),
            ),
            pdfWidgets.Header(
              level: 1,
              child: pdfWidgets.Text('Bulan: $selectedMonth'),
            ),
            pdfWidgets.Paragraph(
              text: 'Jumlah Servis: ${jumlahServis.toString()}',
            ),
            pdfWidgets.Paragraph(
              text: 'Jumlah Barang: ${totalBarang.toString()}',
            ),
            pdfWidgets.Paragraph(
              text:
                  'Total Biaya Servis: Rp ${formatCurrency(jumlahTotalPendapatan)}',
            ),
            pdfWidgets.Paragraph(
              text:
                  'Total Pendapatan Barang: Rp ${formatCurrency(totalPendapatanBarang)}',
            ),
            pdfWidgets.Paragraph(
              text: 'Total Diskon: Rp ${formatCurrency(totalDiskon)}',
            ),
            pdfWidgets.Paragraph(
              text: 'Total Pendapatan Bersih: Rp ${formatCurrency(hargaAkhir)}',
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/service_report.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the saved PDF file
    OpenFile.open(file.path);

    // Show a SnackBar to inform the user that the PDF has been saved.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan servis berhasil disimpan'),
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
        title: Text('Laporan Servis'),
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
            // Card pertama untuk Laporan Bulan dan Jumlah Servis
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
                        DropdownButton<String>(
                          value: selectedMonth,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedMonth = newValue!;
                              fetchDataServis();
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bulan',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          '$selectedMonth',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumlah Servis',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          jumlahServis.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumlah Barang',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          totalBarang.toString(),
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

            // Card kedua untuk Total Biaya Servis, Total Pendapatan Barang, Total Diskon, dan Total Pendapatan Bersih
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
                          'Total Biaya Servis',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Rp ${formatCurrency(jumlahTotalPendapatan)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pendapatan Barang',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Rp ${formatCurrency(totalPendapatanBarang)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Diskon',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Rp ${formatCurrency(totalDiskon)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pendapatan Bersih',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Rp ${formatCurrency(hargaAkhir)}',
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
