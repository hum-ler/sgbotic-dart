import 'dart:async';
import 'dart:io';

import 'package:rpi_gpio/gpio.dart';
import 'package:rpi_gpio/rpi_gpio.dart';

class RpiLab1 {
  /// The length of each pulse.
  static const Duration _blink = Duration(milliseconds: 500);

  GpioOutput _redLed;
  GpioOutput _greenLed;
  GpioOutput _blueLed;

  Future<void> run() async {
    // Indicates whether to stop the blinking and exit.
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

    // Set up the LED GPIO pins as output.
    // 16 = Broadcom GPIO23, 18 = GPIO24, 22 = GPIO25.
    _redLed = gpio.output(16);
    _greenLed = gpio.output(18);
    _blueLed = gpio.output(22);
    GpioOutput currentLed = _getNextLed();

    // Listen to pushes on the button.
    // 37 = GPIO26.
    GpioInput pushButton = gpio.input(37, Pull.up);
    final StreamSubscription<bool> pushes =
        pushButton.values.listen((bool value) {
      if (!value) currentLed = _getNextLed(currentLed);

      return value;
    });

    // Start blinking.
    await for (bool _ in Stream<bool>.periodic(_blink, (i) {
      _redLed.value = false;
      _greenLed.value = false;
      _blueLed.value = false;

      return currentLed.value = i % 2 == 0;
    }).takeWhile((_) => !stop)) {}

    // Cleanup and exit
    _redLed.value = false;
    _greenLed.value = false;
    _blueLed.value = false;
    pushes.cancel();
    gpio.dispose();
  }

  /// Gets the next LED to blink.
  GpioOutput _getNextLed([GpioOutput currentLed]) {
    if (currentLed == _redLed) {
      return _greenLed;
    } else if (currentLed == _greenLed) {
      return _blueLed;
    } else {
      return _redLed;
    }
  }
}
