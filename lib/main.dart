import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ui/screens/home_screen.dart';

// 全局相机列表，供其他页面使用
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化相机列表
  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
    print("Camera init error: $e");
  }
  
  runApp(const LifeBeaconApp());
}

class LifeBeaconApp extends StatelessWidget {
  const LifeBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeBeacon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
