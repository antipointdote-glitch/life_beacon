import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- 1. 通用 (家人) ---
  final TextEditingController _familyCtrl = TextEditingController();
  final TextEditingController _smsCtrl = TextEditingController();

  // --- 2. 荒野 (搜救) ---
  final TextEditingController _wildernessPhoneCtrl = TextEditingController();

  // --- 3. 都市 (报警 + 伪装) ---
  final TextEditingController _urbanPhoneCtrl = TextEditingController();
  final TextEditingController _fakeNameCtrl = TextEditingController();
  
  // 铃声选择
  String _selectedRingtone = "ringtone_ios.mp3";
  final Map<String, String> _ringtoneOptions = {
    "iPhone Style (Global)": "ringtone_ios.mp3",
    "WeChat Style (China)": "ringtone_wechat.mp3",
    "Classic Phone (General)": "ringtone_classic.mp3",
  };

  // 语言设置
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _familyCtrl.text = prefs.getString('family_phone') ?? "";
      _smsCtrl.text = prefs.getString('sms_template') ?? "SOS! I need help. My location is:";
      _wildernessPhoneCtrl.text = prefs.getString('wilderness_phone') ?? "119";
      _urbanPhoneCtrl.text = prefs.getString('urban_phone') ?? "110";
      _fakeNameCtrl.text = prefs.getString('fake_name') ?? "Dad";
      
      _selectedRingtone = prefs.getString('ringtone_asset') ?? "ringtone_ios.mp3";
      if (!_ringtoneOptions.containsValue(_selectedRingtone)) {
        _selectedRingtone = "ringtone_ios.mp3";
      }

      // 语言
      _language = prefs.getString('language') ?? 'en';
      AppStrings.language = _language;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_phone', _familyCtrl.text);
    await prefs.setString('sms_template', _smsCtrl.text);
    await prefs.setString('wilderness_phone', _wildernessPhoneCtrl.text);
    await prefs.setString('urban_phone', _urbanPhoneCtrl.text);
    await prefs.setString('fake_name', _fakeNameCtrl.text);
    await prefs.setString('ringtone_asset', _selectedRingtone);
    await prefs.setString('language', _language);
    AppStrings.language = _language;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuration Saved!")));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppStrings.get('settings_title'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 0. 语言选择 ---
            _buildHeader(AppStrings.get('language'), Colors.white),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<String>(
                value: _language,
                dropdownColor: Colors.grey[900],
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text("English")),
                  DropdownMenuItem(value: 'zh', child: Text("简体中文")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _language = val;
                      AppStrings.language = val;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildHeader(AppStrings.get('section_family'), Colors.pinkAccent),
            _buildCard([
              _buildTextField(AppStrings.get('family_phone'), _familyCtrl, TextInputType.phone, "e.g. Mom's phone"),
              const Divider(color: Colors.white24),
              _buildTextField(AppStrings.get('sms_template'), _smsCtrl, TextInputType.multiline, "Help message...", maxLines: 2),
            ]),
            
            const SizedBox(height: 30),

            _buildHeader(AppStrings.get('section_wild'), Colors.greenAccent),
            _buildCard([
              _buildTextField(AppStrings.get('rescue_number'), _wildernessPhoneCtrl, TextInputType.phone, "Default: 119"),
            ]),

            const SizedBox(height: 30),

            _buildHeader(AppStrings.get('section_urban'), Colors.blueAccent),
            _buildCard([
              _buildTextField(AppStrings.get('police_number'), _urbanPhoneCtrl, TextInputType.phone, "Default: 110"),
              const Divider(color: Colors.white24),
              _buildTextField(AppStrings.get('fake_caller_name'), _fakeNameCtrl, TextInputType.name, "e.g. Dad"),
              
              const Divider(color: Colors.white24),
              
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 5),
                child: Text(AppStrings.get('fake_ringtone'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              DropdownButton<String>(
                value: _selectedRingtone,
                dropdownColor: Colors.grey[900],
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: Container(),
                items: _ringtoneOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedRingtone = newValue);
                  }
                },
              ),
            ]),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: Text(AppStrings.get('save_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, TextInputType type, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }
}
