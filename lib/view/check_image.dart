import 'dart:io';
import 'package:flutter/material.dart';

class CheckImage extends StatefulWidget {
  final String photo;

  const CheckImage({Key? key, required this.photo}) : super(key: key);

  @override
  State<CheckImage> createState() => _CheckImageState();
}

class _CheckImageState extends State<CheckImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Image'),
      ),
      body: Image.file(File(widget.photo)),
    );
  }
}
