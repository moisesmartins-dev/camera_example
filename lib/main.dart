import 'package:camera_example/view/home_view.dart';
import 'package:flutter/material.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: HomeView(),
    ),
  );
}
