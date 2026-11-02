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
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm, // lebar 80mm (thermal)
          297 * PdfPageFormat.mm, // tinggi (A4 sebagai fallback)
          marginAll: 3 * PdfPageFormat.mm,
        ), // ✅ Ukuran kertas thermal 80mm
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER
              pw.Center(
                child: pw.Text(
                  'SIKEPAL APP',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  orders.length > 1 ? 'INVOICE GABUNGAN' : 'INVOICE',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // INFO
              pw.Text('Tgl: ${Formatters.date(orders.first.date)}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Kurir: ${orders.first.courierName ?? "-"}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Toko: ${orders.first.store?.name ?? "-"}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // PRODUK
              ...orders.expand((order) {
                return order.items.map((item) {
                  final subtotal = item.quantity * order.price;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.productName ?? '-',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                              '${item.quantity} x ${Formatters.currency(order.price)}',
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(Formatters.currency(subtotal),
                              style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                    ],
                  );
                });
              }),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(Formatters.currency(grandTotal),
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(
                      fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
