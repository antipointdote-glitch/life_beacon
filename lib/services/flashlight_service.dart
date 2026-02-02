import 'package:torch_light/torch_light.dart';

/// FlashlightService - Abstraction layer for torch/flashlight control
///
/// This service provides a simple interface to turn the device's flashlight
/// on and off, abstracting away the underlying plugin implementation.
class FlashlightService {
  /// Cached availability status
  bool? _isAvailable;

  /// Checks if the device has a torch/flashlight available.
  ///
  /// Returns `true` if a torch is available, `false` otherwise.
  Future<bool> get isTorchAvailable async {
    if (_isAvailable != null) {
      return _isAvailable!;
    }

    try {
      _isAvailable = await TorchLight.isTorchAvailable();
      return _isAvailable!;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  /// Turns the flashlight ON.
  ///
  /// Throws [FlashlightException] if the torch is unavailable or an error occurs.
  Future<void> turnOn() async {
    try {
      await TorchLight.enableTorch();
    } on EnableTorchExistentUserException {
      throw FlashlightException('Another app is using the flashlight');
    } on EnableTorchNotAvailableException {
      throw FlashlightException('Flashlight is not available on this device');
    } on EnableTorchException catch (e) {
      throw FlashlightException('Failed to enable flashlight: ${e.message}');
    } catch (e) {
      throw FlashlightException('Unexpected error: $e');
    }
  }

  /// Turns the flashlight OFF.
  ///
  /// Throws [FlashlightException] if an error occurs.
  Future<void> turnOff() async {
    try {
      await TorchLight.disableTorch();
    } on DisableTorchExistentUserException {
      throw FlashlightException('Another app is controlling the flashlight');
    } on DisableTorchNotAvailableException {
      throw FlashlightException('Flashlight is not available on this device');
    } on DisableTorchException catch (e) {
      throw FlashlightException('Failed to disable flashlight: ${e.message}');
    } catch (e) {
      throw FlashlightException('Unexpected error: $e');
    }
  }

  /// Sets the flashlight state based on the boolean value.
  ///
  /// This is a convenience method useful for the MorseEngine callback.
  /// [on] - `true` to turn on, `false` to turn off
  Future<void> setTorch(bool on) async {
    if (on) {
      await turnOn();
    } else {
      await turnOff();
    }
  }
}

/// Custom exception for flashlight-related errors
class FlashlightException implements Exception {
  final String message;

  FlashlightException(this.message);

  @override
  String toString() => 'FlashlightException: $message';
}
