import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Simple 1D Kalman Filter - noisy sensor data ko smooth karta hai.
class KalmanFilter1D {
  double _estimate = 0.0;
  double _errorCovariance = 1.0;

  final double processNoise;
  final double measurementNoise;

  KalmanFilter1D({this.processNoise = 0.01, this.measurementNoise = 0.5});

  double update(double measurement) {
    _errorCovariance += processNoise;
    final kalmanGain = _errorCovariance / (_errorCovariance + measurementNoise);
    _estimate = _estimate + kalmanGain * (measurement - _estimate);
    _errorCovariance = (1 - kalmanGain) * _errorCovariance;
    return _estimate;
  }

  void reset() {
    _estimate = 0.0;
    _errorCovariance = 1.0;
  }
}

/// Dead reckoning tracker with Kalman Filter + Zero-Velocity Update (ZUPT)
/// drift correction.
class DeadReckoningTracker {
  double positionX = 0.0;
  double positionY = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;
  double heading = 0.0;

  DateTime? _lastUpdateTime;

  final KalmanFilter1D _kalmanX = KalmanFilter1D();
  final KalmanFilter1D _kalmanY = KalmanFilter1D();

  final List<double> _recentAccMagnitudes = [];
  static const int _stationaryWindowSize = 15;
  static const double _stationaryThreshold = 0.35;

  bool isStationary = false;

  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;

  Function(double x, double y, double heading, bool stationary)?
      onPositionUpdate;

  void startTracking() {
    _lastUpdateTime = DateTime.now();

    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final now = DateTime.now();
      final dt = _lastUpdateTime != null
          ? now.difference(_lastUpdateTime!).inMilliseconds / 1000.0
          : 0.0;
      heading += event.z * dt;
      if (heading > 2 * pi) heading -= 2 * pi;
      if (heading < 0) heading += 2 * pi;
    });

    _accelSubscription =
        userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final now = DateTime.now();
      final dt = _lastUpdateTime != null
          ? now.difference(_lastUpdateTime!).inMilliseconds / 1000.0
          : 0.0;
      _lastUpdateTime = now;

      if (dt <= 0 || dt > 1.0) return;

      double smoothAccX = _kalmanX.update(event.x);
      double smoothAccY = _kalmanY.update(event.y);

      double magnitude = sqrt(smoothAccX * smoothAccX + smoothAccY * smoothAccY);
      _recentAccMagnitudes.add(magnitude);
      if (_recentAccMagnitudes.length > _stationaryWindowSize) {
        _recentAccMagnitudes.removeAt(0);
      }

      double avgMagnitude = _recentAccMagnitudes.isNotEmpty
          ? _recentAccMagnitudes.reduce((a, b) => a + b) /
              _recentAccMagnitudes.length
          : 0.0;

      isStationary = avgMagnitude < _stationaryThreshold;

      if (isStationary) {
        velocityX *= 0.7;
        velocityY *= 0.7;
        if (velocityX.abs() < 0.02) velocityX = 0;
        if (velocityY.abs() < 0.02) velocityY = 0;
      } else {
        double worldAccX = smoothAccX * cos(heading) - smoothAccY * sin(heading);
        double worldAccY = smoothAccX * sin(heading) + smoothAccY * cos(heading);

        velocityX += worldAccX * dt;
        velocityY += worldAccY * dt;

        velocityX *= 0.995;
        velocityY *= 0.995;
      }

      positionX += velocityX * dt;
      positionY += velocityY * dt;

      if (onPositionUpdate != null) {
        onPositionUpdate!(positionX, positionY, heading, isStationary);
      }
    });
  }

  void stopTracking() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
  }

  void reset() {
    positionX = 0.0;
    positionY = 0.0;
    velocityX = 0.0;
    velocityY = 0.0;
    heading = 0.0;
    _kalmanX.reset();
    _kalmanY.reset();
    _recentAccMagnitudes.clear();
  }
}