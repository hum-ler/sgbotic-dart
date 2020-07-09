import 'package:meta/meta.dart';
import 'package:rpi_gpio/gpio.dart';

/// Produces a Pulse-width modulation signal.
class Pwm {
  /// The GPIO pin to output this PWM on.
  final GpioOutput _gpioOutput;

  /// The period of this PWM.
  Duration _period;

  /// The duty cycle of this PWM.
  ///
  /// Must be a value between 0.0 to 1.0.
  double _dutyCycle;

  Pwm(
    GpioOutput gpioOutput, {
    @required Duration period,
    @required double dutyCycle,
  })  : assert(gpioOutput != null),
        assert(period != null),
        assert(dutyCycle >= 0.0 && dutyCycle <= 1.0),
        _gpioOutput = gpioOutput,
        _period = period,
        _dutyCycle = dutyCycle;

  void set period(Duration period) {
    if (period != null) _period = period;
  }

  void set dutyCycle(double dutyCycle) {
    if (dutyCycle >= 0.0 && dutyCycle <= 1.0) _dutyCycle = dutyCycle;
  }

  /// Indicates whether the signal should stop.
  bool _stop = false;

  /// Starts this PWM signal.
  Future<void> start() async {
    while (!_stop) {
      await _doCycle();
    }
  }

  /// Stops this PWM signal after the current cycle completes.
  void stop() => _stop = true;

  void _doCycle() async {
    Duration onDuration =
        Duration(microseconds: (_period.inMicroseconds * _dutyCycle).round());
    Duration offDuration = _period - onDuration;

    if (_dutyCycle != 0.0) _gpioOutput.value = true;
    await Future.delayed(onDuration);
    if (_dutyCycle != 1.0) _gpioOutput.value = false;
    await Future.delayed(offDuration);
  }
}

extension GpioOutputExtension on GpioOutput {
  /// Creates a quick method to get a Pwm from a GpioOutput.
  Pwm pwm({
    @required Duration period,
    @required double dutyCycle,
  }) {
    return Pwm(
      this,
      period: period,
      dutyCycle: dutyCycle,
    );
  }
}
