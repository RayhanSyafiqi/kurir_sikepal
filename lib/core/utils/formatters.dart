import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTime = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String grade(String? g) => g == null ? '-' : 'Grade $g';

  static String category(String? c) {
    switch (c) {
      case 'SCHOOL':
        return 'Sekolah';
      case 'NON_SCHOOL':
        return 'Non Sekolah';
      case 'ORDER':
        return 'Pesanan';
      default:
        return '-';
    }
  }

  static String price(String? p) {
    switch (p) {
      case 'SEVEN_THOUSAND':
        return 'Rp 7.000';
      case 'SEVEN_FIVE_THOUSAND':
        return 'Rp 7.500';
      case 'EIGHT_THOUSAND':
        return 'Rp 8.000';
      case 'NINE_THOUSAND':
        return 'Rp 9.000';
      case 'ELEVEN_THOUSAND':
        return 'Rp 11.000';
      default:
        return '-';
    }
  }

  static String paymentMethod(String? m) {
    switch (m) {
      case 'DAILY':
        return 'Harian';
      case 'WEEKLY':
        return 'Mingguan';
      case 'MONTHLY':
        return 'Bulanan';
      default:
        return '-';
    }
  }

  static String orderStatus(String? s) {
    switch (s) {
      case 'DRAFT':
        return 'Draft';
      case 'DELIVERED':
        return 'Dikirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Batal';
      default:
        return '-';
    }
  }

  static String paymentStatus(String? s) {
    switch (s) {
      case 'UNPAID':
        return 'Belum Bayar';
      case 'PAID':
        return 'Dibayar';
      case 'VERIFIED':
        return 'Terverifikasi';
      default:
        return '-';
    }
  }

  static String storeStatus(String? s) {
    switch (s) {
      case 'ACTIVE':
        return 'Aktif';
      case 'INACTIVE':
        return 'Nonaktif';
      default:
        return '-';
    }
  }
}
