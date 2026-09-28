import 'package:tflite_flutter/tflite_flutter.dart';

class AISpeedModel {
  late Interpreter _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/speed_model.tflite',
    );

    _isLoaded = true;

    print('AI Speed Model loaded successfully');
    print('Input shape: ${_interpreter.getInputTensor(0).shape}');
    print('Output shape: ${_interpreter.getOutputTensor(0).shape}');
  }

  Future<double> predictSpeed(
    List<List<double>> sensorWindow,
  ) async {
    if (!_isLoaded) {
      throw Exception('AI Speed Model is not loaded');
    }

    if (sensorWindow.length != 20) {
      throw Exception(
        'Expected 20 sensor samples, got ${sensorWindow.length}',
      );
    }

    for (final sample in sensorWindow) {
      if (sample.length != 12) {
        throw Exception(
          'Each sensor sample must contain 12 features',
        );
      }
    }

    final input = [sensorWindow];

    final output = [
      [0.0]
    ];

    _interpreter.run(input, output);

    return output[0][0];
  }

  void dispose() {
    if (_isLoaded) {
      _interpreter.close();
      _isLoaded = false;
    }
  }
}