import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dimension Tool',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _imageBytes;
  bool _loading = false;
  List<dynamic> _results = [];
  String _error = '';

  Future<void> _pickAndMeasure() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _loading = true;
      _results = [];
      _error = '';
    });

    try {
      final uri = Uri.parse('http://127.0.0.1:8000/measure');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'image.jpg'),
      );
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() {
        _results = data['objects'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Dimension Tool')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageBytes != null) Image.memory(_imageBytes!, height: 250),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickAndMeasure,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image & Measure'),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_results.isNotEmpty) ...[
              const Text(
                'Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._results.map(
                (obj) => Card(
                  child: ListTile(
                    title: Text(obj['label'].toString().toUpperCase()),
                    subtitle: Text(
                      'Width: ${obj['estimated_width_cm']} cm\nHeight: ${obj['estimated_height_cm']} cm\nConfidence: ${obj['confidence']}',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
