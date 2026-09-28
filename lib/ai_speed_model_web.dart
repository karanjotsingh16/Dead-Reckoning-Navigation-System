import 'dart:convert';
import 'dart:js_interop';

@JS('aiSpeedModelLoad')
external JSPromise<JSAny?> _loadModel(String url);

@JS('aiSpeedModelPredictJson')
external JSPromise<JSNumber> _predictSpeed(JSString json);

@JS('aiSpeedModelDispose')
external void _disposeModel();

class AISpeedModel {
  bool _isLoaded = false;

  Future<void> loadModel() async {
    await _loadModel(
      'assets/assets/speed_model.tflite',
    ).toDart;

    _isLoaded = true;

    print('AI Speed Model loaded successfully');
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

    final json = jsonEncode(sensorWindow);

    final result = await _predictSpeed(json.toJS).toDart;

    return result.toDartDouble;
  }

  void dispose() {
    if (_isLoaded) {
      _disposeModel();
      _isLoaded = false;
    }
  }
}