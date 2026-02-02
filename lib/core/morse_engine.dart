import 'dart:async';
import 'package:torch_light/torch_light.dart';
import '../services/audio_service.dart';

class MorseEngine {
  final int _unitTime = 200; 
  bool _isTransmitting = false;
  final AudioService _audioService = AudioService();

  MorseEngine() {
    _audioService.init();
  }

  void stop() {
    _isTransmitting = false;
    _torch(false);
    _audioService.stop();
  }

  // --- 模式 A: 普通 SOS (保持不变) ---
  Future<void> transmitSOS() async {
    if (_isTransmitting) return;
    _isTransmitting = true;
    
    while (_isTransmitting) {
      await _transmitChar("..."); 
      await _wait(3);
      await _transmitChar("---"); 
      await _wait(3);
      await _transmitChar("..."); 
      await _wait(7); 
    }
  }

  // --- 模式 B: 都市爆闪 (已修复声音问题) ---
  Future<void> startStrobe() async {
    if (_isTransmitting) return;
    _isTransmitting = true;

    // 1. 【关键】先启动声音，让它独立循环播放
    // 不要在 while 循环里重复调用它，否则会结巴
    _audioService.startContinuousSiren();

    // 2. 进入死循环，只处理灯光
    while (_isTransmitting) {
      try {
        // 亮灯
        await TorchLight.enableTorch();
        // 亮 40ms (极快)
        await Future.delayed(const Duration(milliseconds: 40)); 

        // 灭灯
        await TorchLight.disableTorch();
        // 灭 40ms
        await Future.delayed(const Duration(milliseconds: 40)); 
        
      } catch (e) {
        print("Strobe error: $e");
        _isTransmitting = false; // 出错强行停止
      }
    }
    
    // 3. 循环结束后，确保声音停止
    _audioService.stop();
  }

  // --- 辅助方法 ---
  Future<void> _transmitChar(String code) async {
    for (int i = 0; i < code.length; i++) {
      if (!_isTransmitting) break;
      int duration = (code[i] == '.') ? 1 : 3;
      await _flash(duration);
      await _wait(1);
    }
  }

  Future<void> _flash(int units) async {
    try {
      // SOS模式下，每次亮灯都伴随一次短促的滴声
      await Future.wait([
        TorchLight.enableTorch(),
        _audioService.playBeep(), 
      ]);
    } catch (e) {}
    await Future.delayed(Duration(milliseconds: _unitTime * units));
    try {
      await TorchLight.disableTorch();
    } catch (e) {}
  }

  Future<void> _wait(int units) async {
    await Future.delayed(Duration(milliseconds: _unitTime * units));
  }
  
  Future<void> _torch(bool on) async {
    try {
      on ? await TorchLight.enableTorch() : await TorchLight.disableTorch();
    } catch (e) {}
  }
}
