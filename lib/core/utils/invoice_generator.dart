import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/order_model.dart';
import 'formatters.dart';

class InvoiceGenerator {
  static Future<Uint8List> generate(List<Order> orders) async {
    final pdf = pw.Document();
    final grandTotal = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // ================= HEADER =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      orders.length > 1 ? 'INVOICE GABUNGAN' : 'INVOICE',
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      orders.length > 1
                          ? 'Total ${orders.length} Transaksi'
                          : '#${orders.first.id.substring(orders.first.id.length - 6).toUpperCase()}',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'SIKEPAL APP',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tanggal Cetak: ${Formatters.date(DateTime.now())}',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.grey400),
            pw.SizedBox(height: 20),

            // ================= TABEL PRODUK =================
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Toko / Kurir', 'Produk', 'Qty', 'Subtotal'],
              data: orders.expand((order) {
                return order.items.map((item) {
                  final subtotal = item.quantity * order.price;
                  return [
                    Formatters.date(order.date),
                    '${order.store?.name ?? "-"}\n(Kurir: ${order.courierId.isNotEmpty ? "Kurir" : "-"})', // Fallback jika nama tidak ada di model
                    item.productName ?? '-',
                    item.quantity.toString(),
                    Formatters.currency(subtotal),
                  ];
                });
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),

            // ================= TOTAL =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total Tagihan Lunas: ',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  Formatters.currency(grandTotal),
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800),
                ),
              ],
            ),
            pw.SizedBox(height: 60),

            // ================= TANDA TANGAN =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Tanda Tangan Kurir',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 60),
                    pw.Text('____________________',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Tanda Tangan Toko',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 60),
                    pw.Text('____________________',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
