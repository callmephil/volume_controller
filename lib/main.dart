import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

void main() {
  if (kIsWeb) return;

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
  // startServer();
}

void startServer() async {
  await FlutterVolumeController.updateShowSystemUI(true);
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print("Server running on IP : ${server.address}:${server.port}");

  await for (HttpRequest request in server) {
    if (request.method == 'POST' && request.uri.path == '/setVolume') {
      var content = await utf8.decoder
          .bind(request)
          .join(); // Get the data from the request
      var data = json.decode(content);
      double volume = data['volume'];
      await FlutterVolumeController.setVolume(volume);
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Volume set to $volume')
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FlutterVolumeController.updateShowSystemUI(true);
      await FlutterVolumeController.getIOSAudioSessionCategory();
      final volume = await FlutterVolumeController.getVolume();
      print(volume);
    });
  }

  final double _maxVolume = 1;
  final double _minVolume = 0;

  // increement volume by 0.1
  void _incrementVolume() async {
    double? currentVolume = await FlutterVolumeController.getVolume();
    double newVolume = currentVolume! + 0.1;
    if (newVolume > _maxVolume) {
      newVolume = _maxVolume;
    }
    await FlutterVolumeController.setVolume(newVolume);
  }

  // decreement volume by 0.1
  void _decrementVolume() async {
    double? currentVolume = await FlutterVolumeController.getVolume();
    double newVolume = currentVolume! - 0.1;
    if (newVolume < _minVolume) {
      newVolume = _minVolume;
    }
    await FlutterVolumeController.setVolume(newVolume);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Volume Control Server'),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () async {
                  _incrementVolume();
                },
              ),
              IconButton(
                icon: const Icon(Icons.volume_down),
                onPressed: () async {
                  _decrementVolume();
                },
              ),
              IconButton(
                icon: const Icon(Icons.volume_off),
                onPressed: () async {
                  await FlutterVolumeController.setVolume(_minVolume);
                },
              ),
            ],
          ),
        ),
        body: const Center(
          child: Text('Running HTTP Server for Volume Control'),
        ),
      ),
    );
  }
}
