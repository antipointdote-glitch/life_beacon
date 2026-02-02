import 'package:geolocator/geolocator.dart';

class LocationService {
  // 检查并请求权限
  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 检查定位服务开关
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false; // 定位没开
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // 获取当前位置流 (Stream)，这样位置一变，UI就自动变
  // ⚠️ 测试阶段：把 distanceFilter 改为 0
  // 这样哪怕你在桌子上稍微挪动一下手机，数据也会更新
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, 
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // 新增：获取上次已知的缓存位置 (用于快速显示)
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  // 初始化检查
  Future<void> init() async {
    await _handlePermission();
  }
}
