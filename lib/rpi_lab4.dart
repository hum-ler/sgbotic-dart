import 'dart:async';
import 'dart:io';

import 'package:rpi_gpio/gpio.dart';
import 'package:rpi_gpio/rpi_gpio.dart';

/// Uses a HC-SR04 ultrasonic sensor.
///
/// The green LED lights up when an object is less than 150cm from the sensor. Otherwise the red LED lights up.
///
/// Press any key to exit.
///
/// ```
/// await RpiLab4().run();
/// ```
class RpiLab4 {
  /// The speed of sound in air at 27°C, 100kPa, 90% relative humidity.
  static const double _speedOfSound = 349.19;

  /// The upper limit of a valid distance detected by HC-SR04 (in cm).
  static const int _distanceUpperBound = 300;

  /// The lower limit of a valid distance detected by HC-SR04 (in cm).
  static const int _distanceLowerBound = 2;

  /// The boundary between "near" and "far" (in cm).
  static const int _nearThreshold = 150;

  /// The length of each pulse.
  static const Duration _pulse = Duration(microseconds: 10);

  /// The period of testing.
  static const Duration _period = Duration(milliseconds: 250);

  /// The pin for signalling a near distance.
  GpioOutput _nearIndicator;

  /// The pin for signalling a far or invalid distance.
  GpioOutput _farIndicator;

  /// The trigger pin on the HC-SR04.
  GpioOutput _trigger;

  /// The echo pin on the HC-SR04.
  GpioInput _echo;

  Future<void> run() async {
    // Indicates whether to stop the looping and exit.
    bool stop = false;

    if (stdin.hasTerminal) {
      // React to keyboard input.
      stdin.lineMode = false; // Don't buffer i.e. don't wait for ENTER.
      stdin.echoMode = false; // Don't echo to console.
      stdin.first.then((_) => stop = true);
    } else {
      // Catch SIGINT (CTRL-C).
      ProcessSignal.sigint.watch().first.then((_) => stop = true);
    }

    Gpio gpio = RpiGpio();

    // Set up the indicator LED pins.
    // 16 = Broadcom GPIO23, 18 = GPIO24.
    _nearIndicator = gpio.output(18);
    _farIndicator = gpio.output(16);

    // Set up the ultrasonic sensor pins.
    // 11 = GPIO17, 13 = GPIO27.
    _trigger = gpio.output(13);
    _echo = gpio.input(11, Pull.up);

    // Start looping.
    await for (bool _ in Stream<bool>.periodic(_period, (i) {
      _doPulse();
      return false;
    }).takeWhile((_) => !stop)) {}

    // Cleanup and exit
    await Future.delayed(_period); // Allow the last cycle to complete.
    _trigger.value = false;
    _nearIndicator.value = false;
    _farIndicator.value = false;
    gpio.dispose();
  }

  /// Sends out a pulse and reads the echo.
  void _doPulse() async {
    // Send a pulse.
    _trigger.value = true;
    await Future.delayed(_pulse);
    _trigger.value = false;

    // Listen to the echo.
    while (!_echo.value) {
      await Future.delayed(Duration.zero);
    }
    Stopwatch stopwatch = Stopwatch()..start();
    while (_echo.value) {
      await Future.delayed(Duration.zero);
    }
    stopwatch.stop();

    // Calculate the distance.
    double distance =
        stopwatch.elapsedMicroseconds * 0.00005 * _speedOfSound; // In cm.

    // Set the correct indicator.
    if (distance < _distanceUpperBound && distance > _distanceLowerBound) {
      _nearIndicator.value = distance < _nearThreshold;
      _farIndicator.value = distance >= _nearThreshold;
    }
  }
}
