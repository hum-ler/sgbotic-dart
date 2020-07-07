import 'dart:async';
import 'dart:io';

import 'package:rpi_gpio/gpio.dart';
import 'package:rpi_gpio/rpi_gpio.dart';

import 'pwm.dart';

class RpiLab2 {
  /// The period of the PWM.
  static const Duration _period = Duration(milliseconds: 10);

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
    GpioOutput led = gpio.output(22);

    int counter = 0;
    bool rampUp = true;
    Pwm pwm = led.pwm(_period, counter.toDouble());
    pwm.start();
    while (!stop) {
      await Future.delayed(const Duration(milliseconds: 10), () {
        if (counter == 0) {
          rampUp = true;
        } else if (counter == 10) {
          rampUp = false;
        }

        counter += rampUp ? 1 : -1;

        pwm.dutyCycle = counter / 10.0;
      });
    }
    pwm.stop();

    // Cleanup and exit
    await Future.delayed(_period); // Allow the last cycle to complete.
    led.value = false;
    gpio.dispose();
  }
}
