import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: DropdownAndButton(),
      ),
    );
  }
}

class DropdownAndButton extends StatefulWidget {
  @override
  _DropdownAndButtonState createState() => _DropdownAndButtonState();
}

class _DropdownAndButtonState extends State<DropdownAndButton> {
  String _selectedItem = '',
      Predicted = '',
      MODEL_PATH = "assets/flowers.tflite";
  int INPUT_SIZE = 192;
  final List<String> _items = [
        '',
        'flower1',
        'flower2',
        'flower3',
        'flower4',
        'flower5'
      ],
      items = ['daisy', 'dandelion', 'roses', 'sunflowers', 'tulips'];
  Interpreter? tfliteInterpreter;
  late ByteBuffer imgData;
  late List<List<dynamic>> outputProbability;

  bool doThing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          child: DropdownButton<String>(
            value: _selectedItem,
            onChanged: (String? newValue) {
              setState(() {
                _selectedItem = newValue!;
                doThing = true;
              });
            },
            items: _items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 100),
        !doThing
            ? Container()
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/${_selectedItem}.png'),
                    fit: BoxFit
                        .cover, // Adjust the image fit as per your requirement
                  ),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: 200, // Adjust the height as per your requirement
                ),
              ),
        const SizedBox(height: 100),
        ElevatedButton(
          onPressed: () {
            loadModel();
          },
          child: const Text('Predicted'),
        ),
        const SizedBox(
          height: 40,
        ),
        Text(Predicted)
      ],
    );
  }

  Future<void> loadModel() async {
    try {
      tfliteInterpreter = await Interpreter.fromAsset(MODEL_PATH);
    } on FileSystemException catch (e) {
      print("Failed to load model: $e");
    }

    imgData = Uint8List(1 * INPUT_SIZE * INPUT_SIZE * 3 * 4).buffer;

    outputProbability = List.generate(1, (_) => List.filled(5, 0.0));

    classifyImage('assets/${_selectedItem}.png');
  }

  void classifyImage(String imagePath) async {
    try {
      final ByteData imageBytes = await rootBundle.load(imagePath);
      Uint8List imageUint8List = imageBytes.buffer.asUint8List();
      final image = decodeImage(imageUint8List);

      final resizedImage =
          copyResize(image!, width: INPUT_SIZE, height: INPUT_SIZE);

      convertImageToByteBuffer(resizedImage);

      tfliteInterpreter!.run(imgData, outputProbability);

      final predictedLabelIndex = getPredictedLabel(outputProbability[0]);

      Predicted = items[predictedLabelIndex];
      setState(() {});
    } catch (e) {
      print('eeeeeeee$e');
    }
  }

  void convertImageToByteBuffer(image) {
    var pixelIndex = 0;
    Float32List floatList = imgData.asFloat32List();
    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = image.getPixel(x, y);
        floatList[pixelIndex++] = (getRed(pixel) / 255.0);
        floatList[pixelIndex++] = (getGreen(pixel) / 255.0);
        floatList[pixelIndex++] = (getBlue(pixel) / 255.0);
      }
    }
  }

  int getPredictedLabel(List<dynamic> probabilities) {
    var maxIndex = -1;
    var maxProbability = 0.0;
    for (var i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProbability) {
        maxProbability = probabilities[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }
}
