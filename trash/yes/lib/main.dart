import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _prediction = ''; 
  Color _boxColor = Colors.grey; 

  Future<void> _pickImageFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _sendImageToServer(_image!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _sendImageToServer(_image!);
    }
  }

  Future<void> _sendImageToServer(File image) async {
    // Convert the image to a base64 string
    List<int> imageBytes = await image.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    // Create a request body
    var requestBody = jsonEncode({"image_base64": base64Image});

    // Send the request to FastAPI server
    var response = await http.post(
      Uri.parse(
          'http://10.0.2.2:8000/predict/'), // Use this URL in the emulator
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      // Parse the response
      var jsonResponse = json.decode(response.body);
      // Update prediction based on the value returned
      setState(() {
        if (jsonResponse['prediction'] == 0) {
          _prediction = 'Biodegradable';
          _boxColor = Colors.green.shade200; 
        } else {
          _prediction = 'Non-biodegradable';
          _boxColor = Colors.red.shade200; 
        }
      });
      print('Prediction: $_prediction');
    } else {
      print('Error: ${response.reasonPhrase}');
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trash Classifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _image != null
                ? Padding(
                    padding:
                        const EdgeInsets.all(16.0),
                    child: Image.file(
                      _image!,
                      height: 200, 
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No image selected',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromCamera,
                  child: Text('Capture Trash Image'),
                ),
                SizedBox(width: 20), 
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: Text('Upload from Gallery'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Prediction box
            _prediction.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _boxColor, 
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black38, 
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Prediction: $_prediction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold, 
                      ),
                    ),
                  )
                : Container(), 
          ],
        ),
      ),
    );
  }
}
