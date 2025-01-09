import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String fileUrl;
  final bool isLocal;
  const PdfViewerScreen({super.key, required this.fileUrl, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: isLocal ?
        SfPdfViewer.file(
            File(fileUrl))
            : SfPdfViewer.network(fileUrl));
  }
}
