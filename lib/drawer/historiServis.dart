import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:new_flutter_app/pages/home_page.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class HistoriServisPage extends StatefulWidget {
  const HistoriServisPage({Key? key}) : super(key: key);

  @override
  State<HistoriServisPage> createState() => _HistoriServisPageState();
}

class _HistoriServisPageState extends State<HistoriServisPage> {
  Query dbRef = FirebaseDatabase.instance.reference().child('transaksiServis');
  int itemCount = 0;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    getDevices();
  }

  Future<void> fetchData() async {
    if (isSearching) {
      String searchText = searchController.text.trim();

      Query query = dbRef.orderByKey().limitToLast(50);

      // Perform a compound query using 'idServis' OR 'kodePelanggan'
      query =
          dbRef.orderByChild('idServis').equalTo(searchText).limitToLast(50);
      DataSnapshot snapshotByIdServis = await query.get();

      // If no data found with 'idServis', then search by 'kodePelanggan'
      if (!snapshotByIdServis.exists) {
        query = dbRef
            .orderByChild('kodePelanggan')
            .equalTo(searchText)
            .limitToLast(50);
        DataSnapshot snapshotBykodePelanggan = await query.get();

        if (snapshotBykodePelanggan.exists) {
          setState(() {
            itemCount = snapshotBykodePelanggan.children.length;
            hasData = true; // Set the flag to true since data is found
          });
        } else {
          setState(() {
            itemCount =
                0; // Reset the itemCount since there are no matching items
            hasData = false; // Set the flag to false since no data is found
          });
        }
      } else {
        setState(() {
          itemCount = snapshotByIdServis.children.length;
          hasData = true; // Set the flag to true since data is found
        });
      }
    } else {
      // When not searching, get the last 50 items
      Query query = dbRef.orderByKey().limitToLast(50);
      DataSnapshot snapshot = await query.get();

      if (snapshot.exists) {
        setState(() {
          itemCount = snapshot.children.length;
          hasData = true; // Set the flag to true since data is found
        });
      } else {
        setState(() {
          itemCount =
              0; // Reset the itemCount since there are no matching items
          hasData = false; // Set the flag to false since no data is found
        });
      }
    }
  }

  Widget buildListItem(DataSnapshot snapshot) {
    Map<dynamic, dynamic> transaksi = snapshot.value as Map<dynamic, dynamic>;

    String idServis = transaksi['idServis'] ?? '';
    String dateTime = transaksi['dateTime'] ?? '';
    String kodePelanggan = transaksi['kodePelanggan'] ?? '';
    String namaPelanggan = transaksi['namaPelanggan'] ?? '';
    String kerusakan = transaksi['keluhan'] ?? '';
    String catatan = transaksi['catatan'] ?? '';
    List<Map>? items = (transaksi['items'] as List<dynamic>?)?.cast<Map>();
    int biayaServis = transaksi['biayaServis'] ?? 0;
    int totalHargaBarang = transaksi['totalHargaBarang'] ?? 0;
    int diskon = transaksi['diskon'] ?? 0;
    int hargaAkhir = transaksi['hargaAkhir'] ?? 0;
    int bayar = transaksi['bayar'] ?? 0;
    int kembalian = transaksi['kembalian'] ?? 0;

    // Check if the idServis or kodePelanggan matches the search query
    if (isSearching &&
        (kodePelanggan.toLowerCase() != searchController.text.toLowerCase() &&
            idServis.toLowerCase() != searchController.text.toLowerCase())) {
      return SizedBox(); // Skip this item if it doesn't match the search query
    }
    return Card(
      child: Stack(
        children: [
          ListTile(
            title: Text('ID Servis: $idServis',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal dan Waktu: $dateTime'),
                Text('Kode Pelanggan: $kodePelanggan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Nama Pelanggan: $namaPelanggan'),
                Text('Keluhan: $kerusakan'),
                Text('Catatan: $catatan'),
                Text('Items:'),
                if (items != null && items.isNotEmpty)
                  Column(
                    children: items.map((item) {
                      String idBarang = item['idBarang'] ?? '';
                      String namaBarang = item['namaBarang'] ?? '';
                      int hargaBarang = item['hargaBarang'] as int? ?? 0;
                      int jumlahItem = item['jumlahBarang'] ?? 0;

                      return Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID Barang: $idBarang'),
                            Text('Nama Barang: $namaBarang'),
                            Text('Harga Barang: Rp ${hargaBarang}'),
                            Text('Jumlah Item: $jumlahItem'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                if (items == null || items.isEmpty)
                  const Text('Tidak ada data items'),
                Text('Subtotal Barang: Rp $totalHargaBarang'),
                Text('Diskon: $diskon%'),
                Text('Biaya Servis: Rp $biayaServis'),
                Text('Bayar: Rp $bayar'),
                Text('Kembalian: Rp $kembalian'),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
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
                                FirebaseDatabase.instance
                                    .reference()
                                    .child('transaksiServis')
                                    .child(snapshot.key!)
                                    .remove();
                                Navigator.of(context).pop();
                                fetchData();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.delete),
                ),
                IconButton(
                  onPressed: () {
                    _selectPrinter(transaksi, items);
                  },
                  icon: Icon(Icons.print),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        SizedBox(height: 5), // Jarak antara teks dan teks yang ditambahkan
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

  String formatCurrency(int value) {
    final format = NumberFormat("#,###");
    return format.format(value);
  }

  void getDevices() async {
    devices = await printer.getBondedDevices();
    setState(() {});
  }

  void _selectPrinter(Map<dynamic, dynamic> transaksi, List<Map>? items) async {
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

      printReceipt(selectedDevice, transaksi, items);
    }
  }

  void searchList(String query) {
    searchController.text = query; // Update the search controller's text

    if (query.isNotEmpty) {
      setState(() {
        isSearching = true;
      });
    } else {
      setState(() {
        isSearching = false;
      });
    }

    fetchData(); // Fetch data based on the search query
  }

  void printReceipt(BluetoothDevice selectedDevice,
      Map<dynamic, dynamic> transaksi, List<Map>? items) {
    try {
      printer.connect(selectedDevice).then((_) {
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
        printer.printCustom('ID Servis: ${transaksi['idServis']}', 1, 0);
        printer.printCustom('Date/Time: ${transaksi['dateTime']}', 1, 0);
        printer.printCustom('--------------------------------', 0, 0);
        printer.printCustom(
            'Kode Pelanggan: ${transaksi['kodePelanggan']}', 1, 0);
        printer.printCustom(
            'Nama Pelanggan: ${transaksi['namaPelanggan']}', 1, 0);
        printer.printCustom('--------------------------------', 0, 0);
        printer.printCustom('Keluhan: ${transaksi['keluhan']}', 1, 0);
        printer.printCustom('Catatan: ${transaksi['catatan']}', 1, 0);
        printer.printNewLine();
        printer.printCustom('--------------------------------', 0, 0);
        printer.printCustom('Items               Qty   Price', 0, 0);
        if (items != null && items.isNotEmpty) {
          for (var item in items) {
            String itemName = item['namaBarang'] ?? '';
            int quantity = item['jumlahBarang'] ?? 0;
            int price = item['hargaBarang'] ?? 0;

            // Wrap nama Barang if it exceeds 18 characters
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
        }
        printer.printNewLine();
        printer.printCustom('--------------------------------', 0, 0);
        double totalDiskon =
            (transaksi['totalHargaBarang'] * transaksi['diskon']) /
                100; // Calculate totalDiskon

        String harga =
            'Rp ${formatCurrency(transaksi['totalHargaBarang'].toInt())}';
        String diskon = '${transaksi['diskon'].toStringAsFixed(0)}%';
        int jumlahItem = 0;

        if (items != null && items.isNotEmpty) {
          for (var item in transaksi['items']) {
            int quantity = item['jumlahBarang'] ?? 0;
            jumlahItem += quantity;
          }
        }

        String potonganHarga = 'Total Diskon'.padRight(20) +
            'Rp ${formatCurrency(totalDiskon.toInt())}';

        String totalItem = jumlahItem.toString();
        String formattedTotalItem = totalItem.padRight(3);

        String totalItemLabel = 'Total Item';
        String totalItemColumn = totalItemLabel.padRight(15);
        String hargaColumn = 'Rp ' +
            formatCurrency(transaksi['totalHargaBarang'].toInt()).padRight(2);

        printer.printCustom(
            '$totalItemColumn$formattedTotalItem  $hargaColumn', 1, 0);

        printer.printCustom('Diskon'.padRight(20) + diskon, 1, 0);
        printer.printCustom(potonganHarga, 1, 0);
        printer.printCustom(
            'Total '.padRight(20) +
                'Rp ${formatCurrency(transaksi['hargaAkhir'].toInt())}',
            1,
            0);
        printer.printCustom(
            'Biaya Servis '.padRight(20) +
                'Rp ${formatCurrency(transaksi['biayaServis'].toInt())}',
            1,
            0);

        printer.printCustom('--------------------------------', 0, 0);
        printer.printCustom(
            'Total '.padRight(20) +
                'Rp ${formatCurrency(transaksi['totalAkhir'].toInt())}',
            1,
            0);
        printer.printCustom(
            'Bayar '.padRight(20) +
                'Rp ${formatCurrency(transaksi['bayar'].toInt())}',
            1,
            0);
        printer.printCustom(
            'Kembalian '.padRight(20) +
                'Rp ${formatCurrency(transaksi['kembalian'].toInt())}',
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
          'Histori Servis',
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
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Transaksi : $itemCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                searchList(value);
                searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: searchController.text.length),
                );
              },
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Cari ID Servis atau Kode Pelanggan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
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
          Expanded(
            child: hasData
                ? FirebaseAnimatedList(
                    query: dbRef,
                    itemBuilder: (BuildContext context, DataSnapshot snapshot,
                        Animation<double> animation, int index) {
                      return buildListItem(snapshot);
                    },
                  )
                : buildNoDataWidget(),
          ),
        ],
      ),
    );
  }
}
