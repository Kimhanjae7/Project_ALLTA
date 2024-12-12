import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isFocused = true;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isFocused = true;
    } else if (state == AppLifecycleState.paused) {
      if (_isRunning && _seconds >= 3) {
        _pauseTimer();
        print('Timer paused due to app going to background');
      }
      _isFocused = false;
    }
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  void _startTimer() {
    if (!_isRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
      _isRunning = true;
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    }
  }

  Future<void> _resetTimer() async {
  final userId = await _fetchUserIdByEmail(userEmail);
  if (userId != null) {
    await _callCalculateTimeAndPointsProc(userId);
  }

  final formattedTime = _formatTime(_seconds); // 공부 시간 포맷
  final points = _calculatePoints(_seconds); // 포인트 계산

  _timer?.cancel();
  setState(() {
    _seconds = 0;
    _isRunning = false;
  });

  // 팝업창 띄우기
  if (context.mounted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 팝업창 둥근 모서리
          ),
          backgroundColor: Color(0xFFECEFF1), // 팝업창 배경색
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "집중 완료",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "$formattedTime 집중하셨습니다\n$points 포인트가 쌓였습니다",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 팝업 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8D6E63), // 버튼 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


  int _calculatePoints(int seconds) {
    // 예시 포인트 계산 로직: 1분당 10포인트
    return (seconds ~/ 60) * 100;
  }

  Future<int?> _fetchUserIdByEmail(String? email) async {
    if (email == null) return null;
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/get-user-id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userEmail': userEmail}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['user_id'];
    } else {
      print('Failed to fetch user ID: ${response.body}');
      return null;
    }
  }

  Future<void> _callCalculateTimeAndPointsProc(int userId) async {
    final String url = 'http://116.124.191.174:15023/calculate-time-and-points';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'input_record_time': _formatTime(_seconds),
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Procedure called successfully');
      } else {
        print('Failed to call procedure: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 102, 91, 77),
        centerTitle: true,
        title: Text(
          'Study Timer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/timer_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      fontFamily: 'Digital7',
                      fontSize: 65,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 8, left: 20, top: 40),
                      child: _buildImageButton('assets/images/button.png', _startTimer),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: _buildImageButton('assets/images/button.png', _pauseTimer),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20, left: 10, top: 40),
                      child: _buildImageButton('assets/images/button.png', _resetTimer),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        assetPath,
        width: 75,
        height: 75,
      ),
    );
  }
}
