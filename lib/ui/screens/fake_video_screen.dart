import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../main.dart'; 

class FakeVideoScreen extends StatefulWidget {
  final String callerName;
  final String ringtone;

  const FakeVideoScreen({super.key, required this.callerName, required this.ringtone});

  @override
  State<FakeVideoScreen> createState() => _FakeVideoScreenState();
}

class _FakeVideoScreenState extends State<FakeVideoScreen> {
  CameraController? _controller;
  final AudioPlayer _player = AudioPlayer();
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  // 1. 播放铃声
  void _playRingtone() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/${widget.ringtone}')); 
  }

  // 2. 接听视频
  void _answerCall() async {
    await _player.stop();
    await _initFrontCamera();
    setState(() => _isAnswered = true);
  }

  // 初始化前置摄像头
  Future<void> _initFrontCamera() async {
    try {
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  // 挂断/拒绝
  void _endCall() {
    _player.stop();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _player.stop();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isAnswered 
          ? _buildConnectedUI()
          : _buildIncomingUI(),
    );
  }

  // --- 界面 A: 来电界面 ---
  Widget _buildIncomingUI() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                const Text("Incoming Video Call...", style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 20),
                Text("${widget.callerName} ❤️", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("FaceTime Video", style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBtn(Icons.call_end, Colors.red, "Decline", _endCall),
                  _buildActionBtn(Icons.videocam, Colors.green, "Accept", _answerCall),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- 界面 B: 接通后的摄像头界面 ---
  Widget _buildConnectedUI() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 摄像头画面
        CameraPreview(_controller!),
        
        // 2. 伪装 UI 层
        SafeArea(
          child: Column(
            children: [
              // 顶部状态
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text("${widget.callerName} ❤️ (00:01)", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // 右上角小窗口
                    Container(
                      width: 90, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[900], 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: Colors.white38)
                      ),
                      child: const Center(child: Icon(Icons.person, color: Colors.white54, size: 40)),
                    )
                  ],
                ),
              ),
              const Spacer(),
              // 底部挂断
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIcon(Icons.mic_off),
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),
                    _buildIcon(Icons.flip_camera_ios),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white))
      ],
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
