import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 로그아웃 요청에 사용할 패키지
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  int userId = 1;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    WidgetsBinding.instance.addObserver(this); // Observer 추가
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer 제거
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Adroid
    // 앱 라이프사이클 상태 변경 감지
    // 현재 백그라운드 진입으로 로그아웃 구현 -> 추후 변경해야함
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // 앱이 종료되거나 백그라운드로 진입하는 상태일 때
      await logout();
    }
  }

  Future<void> logout() async {
    // 서버에 POST 요청
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/logout'), // 서버 주소
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId
        }),
      );
  }

  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId') ?? 1;
      print('userId = ${userId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Screen App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

void main() {
  runApp(MyApp());
}
