import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;
  const FullScreenImageScreen({super.key, required this.imageUrl, this.isLocal = false});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text("", style: TextStyle(color: Colors.white)),
      ),
      body: isLocal
          ? Image.file(
        File(imageUrl),
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
      )
          : _buildNetworkImage(imageUrl, size),
    );
  }

  Widget _buildNetworkImage(String url, Size size) {
    return Image.network(
      url,
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child; // Once the image is loaded, display the image.
        } else {
          double progress = loadingProgress.expectedTotalBytes != null
              ? (loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1))
              : 0;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(value: progress),
                SizedBox(height: 20),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
