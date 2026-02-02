import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final VolumeController _volumeController = VolumeController();
  
  Uint8List? _sosWav;   
  Uint8List? _sirenWav; 
  
  // 记住原来的音量
  double _previousVolume = 0.5; 

  Future<void> init() async {
    _sosWav = _generateSineWav(3000, 0.2); 
    _sirenWav = _generateSineWav(4200, 2.0); 
  }

  // 播放普通 SOS (点按式)
  Future<void> playBeep() async {
    if (_sosWav != null) {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
      await _player.play(BytesSource(_sosWav!));
    }
  }

  // 播放都市警报 (带强制最大音量)
  Future<void> startContinuousSiren() async {
    if (_sirenWav != null) {
      // 1. 记住现在的音量
      _previousVolume = await _volumeController.getVolume();
      
      // 2. 【暴力】直接拉到 100% (1.0)
      // showSystemUI: false 表示不显示系统的音量条弹窗
      _volumeController.setVolume(1.0, showSystemUI: false); 

      // 3. 开始播放
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.stop();
      await _player.play(BytesSource(_sirenWav!));
    }
  }

  // 停止播放 (并恢复音量)
  Future<void> stop() async {
    await _player.stop();
    
    // 恢复之前的音量 (做一个有素质的 App)
    try {
      _volumeController.setVolume(_previousVolume, showSystemUI: false);
    } catch (e) {
      print("Volume restore error: $e");
    }
  }

  // --- 波形生成器 ---
  Uint8List _generateSineWav(int freq, double duration) {
    const int sampleRate = 44100;
    int numSamples = (duration * sampleRate).toInt();
    int fileSize = 36 + numSamples * 2;
    var bytes = ByteData(fileSize + 8);
    var offset = 0;

    _writeString(bytes, offset, 'RIFF'); offset += 4;
    bytes.setUint32(offset, fileSize, Endian.little); offset += 4;
    _writeString(bytes, offset, 'WAVE'); offset += 4;
    _writeString(bytes, offset, 'fmt '); offset += 4;
    bytes.setUint32(offset, 16, Endian.little); offset += 4;
    bytes.setUint16(offset, 1, Endian.little); offset += 2;
    bytes.setUint16(offset, 1, Endian.little); offset += 2;
    bytes.setUint32(offset, sampleRate, Endian.little); offset += 4;
    bytes.setUint32(offset, sampleRate * 2, Endian.little); offset += 4;
    bytes.setUint16(offset, 2, Endian.little); offset += 2;
    bytes.setUint16(offset, 16, Endian.little); offset += 2;
    _writeString(bytes, offset, 'data'); offset += 4;
    bytes.setUint32(offset, numSamples * 2, Endian.little); offset += 4;

    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double sample = sin(2 * pi * freq * t);
      int value = (sample * 32767).toInt();
      bytes.setInt16(offset, value, Endian.little);
      offset += 2;
    }
    return bytes.buffer.asUint8List();
  }

  void _writeString(ByteData bytes, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
