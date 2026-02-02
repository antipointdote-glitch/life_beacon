import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  final String ringtone;

  const FakeCallScreen({super.key, required this.callerName, required this.ringtone});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  // 播放铃声
  void _playRingtone() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/${widget.ringtone}'));
  }

  // 停止铃声
  void _stopRingtone() {
    _player.stop();
  }

  // 接听电话
  void _answerCall() {
    _stopRingtone();
    setState(() => _isConnected = true);
  }

  // 挂断电话
  void _hangUp() {
    _stopRingtone();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 来电者头像
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            // 来电者名字
            Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _isConnected ? "Connected  00:00" : "Incoming call...", 
              style: TextStyle(color: _isConnected ? Colors.green : Colors.grey, fontSize: 16)
            ),
            const Spacer(),
            // 接听/挂断按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 挂断
                  GestureDetector(
                    onTap: _hangUp,
                    child: Container(
                      width: 70, height: 70,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                  // 接听
                  if (!_isConnected)
                    GestureDetector(
                      onTap: _answerCall,
                      child: Container(
                        width: 70, height: 70,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                        child: const Icon(Icons.call, color: Colors.white, size: 32),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
