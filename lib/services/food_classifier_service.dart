import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FoodPrediction {
  final int index;
  final String classId;
  final String foodName;
  final double confidence;

  FoodPrediction({
    required this.index,
    required this.classId,
    required this.foodName,
    required this.confidence,
  });

  String get confidencePercent {
    return '${(confidence * 100).toStringAsFixed(2)}%';
  }
}

class FoodClassifierService {
  Interpreter? _interpreter;

  List<String> _classIds = [];
  Map<String, String> _labelMap = {};

  int _inputHeight = 224;
  int _inputWidth = 224;
  int _inputChannels = 3;

  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /*
    สำคัญ:
    ถ้า AI ทายเป็น class เดิมซ้ำ ๆ เช่น ต้มยำหมด
    ให้ลองเปลี่ยนค่านี้

    zeroTo255  = ส่งค่า pixel 0-255 เข้าโมเดล
    zeroToOne  = ส่งค่า pixel 0-1 เข้าโมเดล
    minusOneToOne = ส่งค่า pixel -1 ถึง 1 เข้าโมเดล

    ตอนนี้ตั้ง zeroTo255 ก่อน เพราะหลายโมเดล EfficientNet/MobileNet
    ที่ export เป็น TFLite มักคาดหวัง input 0-255
  */
  static const String inputNormalizeMode = 'zeroTo255';

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/food_model_improved.tflite',
      );

      await _loadClassNames();
      await _loadLabels();

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;

      if (inputShape.length == 4) {
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
        _inputChannels = inputShape[3];
      }

      _isModelLoaded = true;

      print('✅ TFLite model loaded');
      print('Input shape: $inputShape');
      print('Input type: ${inputTensor.type}');
      print('Output shape: $outputShape');
      print('Output type: ${outputTensor.type}');
      print('Input normalize mode: $inputNormalizeMode');
      print('Class count: ${_classIds.length}');
      print('Label count: ${_labelMap.length}');
      print('Class IDs: $_classIds');
      print('Labels: $_labelMap');
    } catch (e) {
      _isModelLoaded = false;
      throw Exception('โหลดโมเดลไม่สำเร็จ: $e');
    }
  }

  Future<void> _loadClassNames() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/class_names.json',
    );

    final dynamic decoded = jsonDecode(jsonString);

    if (decoded is List) {
      _classIds = decoded.map((e) => e.toString().trim()).toList();
    } else {
      throw Exception('class_names.json ต้องเป็น List เช่น ["12", "20"]');
    }
  }

  Future<void> _loadLabels() async {
    final labelsText = await rootBundle.loadString(
      'assets/data/labels.txt',
    );

    final lines = labelsText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final Map<String, String> result = {};

    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));

      if (parts.length >= 2) {
        final classId = parts.first.trim();
        final foodName = parts.sublist(1).join(' ').trim();
        result[classId] = foodName;
      }
    }

    _labelMap = result;
  }

  Future<FoodPrediction> predictImage(File imageFile) async {
    final predictions = await predictTopK(
      imageFile,
      topK: 1,
    );

    if (predictions.isEmpty) {
      throw Exception('ไม่พบผลลัพธ์จากโมเดล');
    }

    return predictions.first;
  }

  Future<List<FoodPrediction>> predictTopK(
    File imageFile, {
    int topK = 5,
  }) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('อ่านรูปภาพไม่สำเร็จ');
    }

    final orientedImage = img.bakeOrientation(decodedImage);

    final resizedImage = img.copyResize(
      orientedImage,
      width: _inputWidth,
      height: _inputHeight,
      interpolation: img.Interpolation.linear,
    );

    final inputTensor = _interpreter!.getInputTensor(0);
    final inputType = inputTensor.type.toString().toLowerCase();

    final Object input = inputType.contains('uint8')
        ? _imageToUint8Input(resizedImage)
        : _imageToFloatInput(resizedImage);

    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;

    int outputLength = _classIds.length;

    if (outputShape.length == 2) {
      outputLength = outputShape[1];
    } else if (outputShape.length == 1) {
      outputLength = outputShape[0];
    }

    final output = List.generate(
      1,
      (_) => List<double>.filled(outputLength, 0.0),
    );

    _interpreter!.run(input, output);

    final rawScores = output.first;

    print('Raw output: $rawScores');

    final scores = _convertToProbabilities(rawScores);

    final predictions = _getTopKPredictions(
      scores,
      topK: topK,
    );

    print('====== TOP PREDICTIONS ======');
    for (final p in predictions) {
      print(
        'index=${p.index}, classId=${p.classId}, food=${p.foodName}, confidence=${p.confidencePercent}',
      );
    }
    print('=============================');

    return predictions;
  }

  List<List<List<List<double>>>> _imageToFloatInput(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (y) => List.generate(
          _inputWidth,
          (x) {
            final pixel = image.getPixel(x, y);

            final double r = pixel.r.toDouble();
            final double g = pixel.g.toDouble();
            final double b = pixel.b.toDouble();

            return [
              _normalizePixel(r),
              _normalizePixel(g),
              _normalizePixel(b),
            ];
          },
        ),
      ),
    );
  }

  double _normalizePixel(double value) {
    if (inputNormalizeMode == 'zeroToOne') {
      return value / 255.0;
    }

    if (inputNormalizeMode == 'minusOneToOne') {
      return (value / 127.5) - 1.0;
    }

    return value;
  }

  List<List<List<List<int>>>> _imageToUint8Input(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (y) => List.generate(
          _inputWidth,
          (x) {
            final pixel = image.getPixel(x, y);

            return [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ];
          },
        ),
      ),
    );
  }

  List<double> _convertToProbabilities(List<double> rawScores) {
    final double sum = rawScores.fold(0.0, (a, b) => a + b);
    final bool looksLikeProbability =
        rawScores.every((v) => v >= 0.0 && v <= 1.0) &&
            sum > 0.95 &&
            sum < 1.05;

    if (looksLikeProbability) {
      return rawScores;
    }

    return _softmax(rawScores);
  }

  List<double> _softmax(List<double> logits) {
    final double maxLogit = logits.reduce(math.max);

    final expValues = logits.map((x) {
      return math.exp(x - maxLogit);
    }).toList();

    final double sumExp = expValues.fold(0.0, (a, b) => a + b);

    if (sumExp == 0) {
      return List<double>.filled(logits.length, 0);
    }

    return expValues.map((x) => x / sumExp).toList();
  }

  List<FoodPrediction> _getTopKPredictions(
    List<double> scores, {
    required int topK,
  }) {
    final List<int> indexes = List.generate(
      scores.length,
      (index) => index,
    );

    indexes.sort((a, b) => scores[b].compareTo(scores[a]));

    final int count = math.min(topK, indexes.length);

    return indexes.take(count).map((index) {
      final String classId = index < _classIds.length
          ? _classIds[index]
          : index.toString();

      final String foodName = _labelMap[classId] ?? 'ไม่ทราบชื่ออาหาร';

      return FoodPrediction(
        index: index,
        classId: classId,
        foodName: foodName,
        confidence: scores[index],
      );
    }).toList();
  }

  List<String> getClassIds() {
    return _classIds;
  }

  Map<String, String> getLabelMap() {
    return _labelMap;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}