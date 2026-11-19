import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignaturePadWidget extends StatefulWidget {
  final String title;
  final Function(String? signatureBase64) onSigned;
  final String? initialSignatureBase64;

  const SignaturePadWidget({
    super.key,
    required this.title,
    required this.onSigned,
    this.initialSignatureBase64,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<Offset?> _points = [];
  bool _hasSigned = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSignatureBase64 != null) {
      _hasSigned = true;
    }
  }

  void _clear() {
    setState(() {
      _points.clear();
      _hasSigned = false;
    });
    widget.onSigned(null);
  }

  Future<void> _captureSignature() async {
    if (_points.isEmpty) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(const Offset(0, 0), const Offset(300, 150)),
    );

    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 300, 150), bgPaint);

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 150);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final base64Str = base64Encode(byteData.buffer.asUint8List());
      setState(() {
        _hasSigned = true;
      });
      widget.onSigned(base64Str);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (_points.isNotEmpty || _hasSigned)
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onPanUpdate: (details) {
                final localPos = details.localPosition;
                setState(() {
                  _points.add(localPos);
                });
              },
              onPanEnd: (details) {
                _points.add(null);
                _captureSignature();
              },
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                child: _points.isEmpty && !_hasSigned
                    ? Center(
                        child: Text(
                          'Sign here with finger / stylus / mouse',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
