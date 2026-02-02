class AppStrings {
  // 当前语言代码 ('en' 或 'zh')
  static String language = 'en'; 

  // 字典
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'LifeBeacon',
      'wild_mode': 'WILD',
      'urban_mode': 'URBAN',
      'sos_btn': 'SOS',
      'stop_btn': 'STOP',
      'panic_btn': 'PANIC',
      'fake_call': 'FAKE CALL',
      'fake_video': 'FAKE VIDEO',
      'sms_alarm': 'SMS (TAP) | 110 (HOLD)',
      'call_rescue': 'CALL RESCUE',
      'settings_title': 'Settings',
      'section_family': '❤️ Family Contact (SMS)',
      'section_wild': '🏔️ Wilderness Mode Setup',
      'section_urban': '🏙️ Urban Mode Setup',
      'save_btn': 'SAVE SETTINGS',
      'language': 'Language / 语言',
      'family_phone': 'Family Phone Number',
      'sms_template': 'SOS Message Body',
      'rescue_number': 'Rescue Number (Call)',
      'police_number': 'Police Number (Call)',
      'fake_caller_name': 'Fake Caller Name',
      'fake_ringtone': 'Fake Call Ringtone',
      'sms_family': 'SMS FAMILY',
      'call_phone': 'CALL',
      'sms_tap': 'SMS (TAP)',
      'call_hold': '(HOLD)',
    },
    'zh': {
      'app_name': '生命信标',
      'wild_mode': '野外模式',
      'urban_mode': '城市模式',
      'sos_btn': 'SOS',
      'stop_btn': '停止',
      'panic_btn': '一键爆闪',
      'fake_call': '伪装来电',
      'fake_video': '伪装视频',
      'sms_alarm': '短信报警 (点) | 电话 (长按)',
      'call_rescue': '呼叫急救',
      'settings_title': '设置',
      'section_family': '❤️ 家庭联系人（短信）',
      'section_wild': '🏔️ 野外模式',
      'section_urban': '🏙️ 城市模式',
      'save_btn': '保存设置',
      'language': 'Language / 语言',
      'family_phone': '家庭成员电话',
      'sms_template': 'SOS求救短信模板',
      'rescue_number': '急救电话（通话）',
      'police_number': '报警电话',
      'fake_caller_name': '虚拟电话打给谁',
      'fake_ringtone': '虚拟电话铃声',
      'sms_family': '发求救短信',
      'call_phone': '拨打',
      'sms_tap': '短信（轻按）',
      'call_hold': '（长按）',
    }
  };

  // 获取文字的方法
  static String get(String key) {
    return _localizedValues[language]?[key] ?? key;
  }
}
