import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class ImageStamp {
  ImageStamp._();

  /// Batas ukuran output (byte). Default 1.5 MB
  static const int _maxBytes = 1500000;

  /// Tambahkan timestamp di pojok bawah foto
  /// + resize otomatis kalau melebihi batas
  static Future<Uint8List> addTimestamp(
    Uint8List imageBytes, {
    DateTime? time,
    String? label,
  }) async {
    final ts = time ?? DateTime.now();

    // Decode image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Resize dulu kalau gambar besar (max lebar 1080px)
    const maxWidth = 1080.0;
    int targetWidth = image.width;
    int targetHeight = image.height;
    if (image.width > maxWidth) {
      targetWidth = maxWidth.toInt();
      targetHeight = (image.height * maxWidth / image.width).toInt();
    }

    // Decode ulang dengan target size
    final resizedBytes = await _resizeImage(
      imageBytes,
      targetWidth,
      targetHeight,
    );
    final codec2 = await ui.instantiateImageCodec(resizedBytes);
    final frame2 = await codec2.getNextFrame();
    final image2 = frame2.image;

    final width = image2.width.toDouble();
    final height = image2.height.toDouble();

    // Canvas setup
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw image full
    canvas.drawImage(image2, Offset.zero, Paint());

    // Format tanggal Indonesia
    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(ts);
    final timeStr = DateFormat('HH:mm:ss').format(ts);
    final text = label != null
        ? '$label\n$dateStr • $timeStr WIB'
        : '$dateStr\n$timeStr WIB';

    final fontSize = width / 28;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.4,
      shadows: const [
        Shadow(
          color: Colors.black87,
          blurRadius: 6,
          offset: Offset(1, 1),
        ),
      ],
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width - 40);

    // Background gelap semi transparan
    const padding = 16.0;
    final bgRect = Rect.fromLTWH(
      padding,
      height - tp.height - padding * 2 - 8,
      tp.width + padding * 2,
      tp.height + padding * 2,
    );

    final rrect = RRect.fromRectAndRadius(
      bgRect,
      Radius.circular(fontSize * 0.8),
    );
    canvas.drawRRect(
      rrect,
      // ignore: deprecated_member_use
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // Border oranye kecil di kiri
    canvas.drawRect(
      Rect.fromLTWH(
        bgRect.left,
        bgRect.top,
        4,
        bgRect.height,
      ),
      Paint()..color = const Color(0xFFFF7043),
    );

    // Draw text
    tp.paint(
      canvas,
      Offset(
        bgRect.left + padding,
        bgRect.top + padding,
      ),
    );

    // Convert ke PNG
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image2.width, image2.height);
    final byteData = await rendered.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final out = byteData!.buffer.asUint8List();

    // Kalau masih terlalu besar, kompres ulang dengan resize lebih kecil
    if (out.length > _maxBytes) {
      return _resizeImage(
          out, 800, (image2.height * 800 / image2.width).toInt());
    }

    return out;
  }

  /// Resize gambar dengan lebar/tinggi tertentu
  static Future<Uint8List> _resizeImage(
    Uint8List bytes,
    int targetWidth,
    int targetHeight,
  ) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
