import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/morse_engine.dart';
import '../../core/app_strings.dart';
import '../../services/location_service.dart';
import 'fake_call_screen.dart';
import 'fake_video_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MorseEngine _morseEngine = MorseEngine();
  final LocationService _locationService = LocationService();
  final QuickActions _quickActions = const QuickActions();
  late AnimationController _controller;
  final TextEditingController _phoneController = TextEditingController();

  // 状态变量
  bool _isSOSActive = false;
  bool _isUrbanMode = false;
  Position? _lastPosition;
  String _familyPhone = "";
  String _wildernessPhone = "119";
  String _urbanPhone = "110";
  String _fakeName = "Dad";
  String _smsTemplate = "SOS! I am in danger. My location is:";
  String _ringtoneAsset = "ringtone_ios.mp3";
  String _debugStatus = "Init...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 1), 
      lowerBound: 0.8, 
      upperBound: 1.0
    );
    _initLocation();
    _loadSettings();
    _initQuickActions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _morseEngine.stop();
    super.dispose();
  }

  // --- 初始化方法 ---
  void _initLocation() async {
    await _locationService.init();
    
    final lastPos = await _locationService.getLastKnownPosition();
    if (lastPos != null && mounted) {
      setState(() {
        _lastPosition = lastPos;
        _debugStatus = "Cached Location";
      });
    }

    _locationService.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() {
          _lastPosition = pos;
          _debugStatus = "GPS Fix!";
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _debugStatus = "Error: $e");
    });
  }

  void _initQuickActions() {
    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_sos', localizedTitle: 'START SOS', icon: 'ic_launcher'),
    ]);

    _quickActions.initialize((shortcutType) {
      if (shortcutType == 'action_sos') {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isSOSActive) _toggleActive();
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _familyPhone = prefs.getString('family_phone') ?? "";
        _wildernessPhone = prefs.getString('wilderness_phone') ?? "119";
        _urbanPhone = prefs.getString('urban_phone') ?? "110";
        _fakeName = prefs.getString('fake_name') ?? "Dad";
        _smsTemplate = prefs.getString('sms_template') ?? "SOS! I am in danger. My location is:";
        _ringtoneAsset = prefs.getString('ringtone_asset') ?? "ringtone_ios.mp3";
        _phoneController.text = _familyPhone;
        
        // 语言设置 - 从已保存的设置读取
        AppStrings.language = prefs.getString('language') ?? 'en';
      });
    }
  }

  // 打开设置页面
  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // 始终重新加载设置以刷新语言和其他配置
    _loadSettings();
  }

  Future<void> _saveSettings(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_phone', phone);
    setState(() => _familyPhone = phone);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Family Contact Saved!")),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Emergency Contact", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the phone number of your family or friend who will receive your SOS SMS.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.contact_phone, color: Colors.white54),
                hintText: "Phone Number",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () => _saveSettings(_phoneController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOSMessage() async {
    if (_lastPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wait for GPS lock first!")),
      );
      return;
    }

    if (_familyPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set family contact first!")));
      _openSettings();
      return;
    }

    final String message = 
      "$_smsTemplate\n\n"
      "Lat: ${_lastPosition!.latitude.toStringAsFixed(5)}\n"
      "Lng: ${_lastPosition!.longitude.toStringAsFixed(5)}\n\n"
      "Google Map:\n"
      "http://maps.google.com/?q=${_lastPosition!.latitude},${_lastPosition!.longitude}";

    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: _familyPhone,
      queryParameters: <String, String>{'body': message},
    );

    try {
      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // 通用拨号方法
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- 核心控制逻辑 ---
  void _toggleActive() {
    setState(() => _isSOSActive = !_isSOSActive);

    if (_isSOSActive) {
      _controller.repeat(reverse: true);
      if (_isUrbanMode) {
        _morseEngine.startStrobe(); // 都市：爆闪 + 高频音
      } else {
        _morseEngine.transmitSOS(); // 荒野：SOS + 滴声
      }
    } else {
      _controller.reset();
      _morseEngine.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = _isUrbanMode ? const Color(0xFF0F172A) : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppStrings.get('wild_mode'), style: TextStyle(color: !_isUrbanMode ? Colors.white : Colors.grey, fontSize: 14)),
            Switch(
              value: _isUrbanMode,
              activeColor: Colors.redAccent,
              inactiveThumbColor: Colors.green,
              trackColor: WidgetStateProperty.all(Colors.grey[800]),
              onChanged: (val) {
                if (_isSOSActive) _toggleActive();
                setState(() => _isUrbanMode = val);
              },
            ),
            Text(AppStrings.get('urban_mode'), style: TextStyle(color: _isUrbanMode ? Colors.white : Colors.grey, fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white54), onPressed: _openSettings),
        ],
      ),
      body: Center(
        child: _isUrbanMode ? _buildUrbanUI() : _buildWildernessUI(),
      ),
    );
  }

  // 🌲 荒野模式 UI
  Widget _buildWildernessUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _toggleActive,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSOSActive ? _controller.value : 1.0,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSOSActive ? Colors.red : Colors.grey[900],
                    border: Border.all(color: _isSOSActive ? Colors.redAccent : Colors.white24, width: 2),
                    boxShadow: _isSOSActive ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 50)] : [],
                  ),
                  child: Center(
                    child: Text(_isSOSActive ? AppStrings.get('stop_btn') : AppStrings.get('sos_btn'), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        _buildLocationPanel(),
        const SizedBox(height: 30),

        // 荒野双操作栏
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左边：发短信给家人
            ElevatedButton.icon(
              onPressed: _sendSOSMessage,
              icon: const Icon(Icons.send, size: 20),
              label: Text(AppStrings.get('sms_family')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            
            const SizedBox(width: 15),
            
            // 右边：打搜救电话
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(_wildernessPhone),
              icon: const Icon(Icons.phone_forwarded, size: 20),
              label: Text("${AppStrings.get('call_phone')} $_wildernessPhone"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ],
        )
      ],
    );
  }

  // 🏙️ 都市模式 UI
  Widget _buildUrbanUI() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 第一排：伪装功能 (GHOST SYSTEM)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUrbanCard(AppStrings.get('fake_call'), Icons.phone_in_talk, Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => FakeCallScreen(
                  callerName: _fakeName,
                  ringtone: _ringtoneAsset,
                )));
              }),
              const SizedBox(width: 15),
              _buildUrbanCard(AppStrings.get('fake_video'), Icons.videocam, Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => FakeVideoScreen(
                  callerName: _fakeName,
                  ringtone: _ringtoneAsset,
                )));
              }),
            ],
          ),

          const SizedBox(height: 20),

          // 第二排：一键报警 (SILENT ALARM)
          GestureDetector(
            onTap: _sendSOSMessage,
            onLongPress: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Calling $_urbanPhone...")));
              _makePhoneCall(_urbanPhone);
            },
            child: Container(
              width: 315,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.message_outlined, color: Colors.orangeAccent, size: 30),
                  const SizedBox(width: 10),
                  Text("${AppStrings.get('sms_tap')}  |  $_urbanPhone ${AppStrings.get('call_hold')}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 第三排：PANIC (爆闪 + 尖叫)
          GestureDetector(
            onTap: _toggleActive,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isSOSActive ? _controller.value : 1.0,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSOSActive ? Colors.red : Colors.grey[900],
                      boxShadow: [
                        if (_isSOSActive) BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 40)
                      ],
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSOSActive ? Icons.stop : Icons.warning_amber_rounded, size: 40, color: Colors.white),
                          Text(_isSOSActive ? AppStrings.get('stop_btn') : AppStrings.get('panic_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 辅助样式组件
  Widget _buildUrbanCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150, height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 140, height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: _lastPosition == null 
        ? Text("Waiting for GPS...\n($_debugStatus)", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38))
        : Column(
            children: [
              _buildInfoRow("LAT", _lastPosition!.latitude.toStringAsFixed(5)),
              const SizedBox(height: 8),
              _buildInfoRow("LNG", _lastPosition!.longitude.toStringAsFixed(5)),
              const SizedBox(height: 8),
              _buildInfoRow("ALT", "${_lastPosition!.altitude.toStringAsFixed(1)} m"),
              const SizedBox(height: 8),
              Text(_debugStatus, style: const TextStyle(color: Colors.green, fontSize: 10)),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return SizedBox(
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
