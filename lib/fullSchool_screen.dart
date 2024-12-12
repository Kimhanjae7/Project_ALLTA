import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'medal_list.dart';
import 'dart:convert';
import 'school_medal_list.dart';
import 'package:http/http.dart' as http;

class FullSchoolScreen extends StatefulWidget {
  final int userId;  // 매개변수로 userId 받기

  // 생성자에서 userId를 받아옴
  FullSchoolScreen({required this.userId});

  @override
  _FullSchoolScreenState createState() => _FullSchoolScreenState();
}

class _FullSchoolScreenState extends State<FullSchoolScreen> {
  String schoolName = "";
  int schoolId = 1;
  int schoolLevel = 1;
  int totalTime = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSchoolInfo();
    });
  }

  Future<void> fetchSchoolInfo() async {
    showLoading(context); // 로딩 창 표시
    try{
      // await Future.delayed(Duration(seconds: 1)); // 지연
      // SharedPreferences에서 userId를 가져오는 대신 매개변수로 받은 userId 사용
      final userId = widget.userId; // widget.userId로 userId 가져옴

      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-school-info'), // 서버 API 주소
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'userId': userId}),  // 매개변수 userId를 서버에 전달
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          schoolId = data['school_id'];
          schoolName = data['school_name'];
          schoolLevel = data['school_level'];
          totalTime = data['total_time'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch school info')),
        );
      }
    } finally {
      hideLoading(context); // 로딩 창 숨기기
    }
  }

  String _formatTime(dynamic time) {
    if (time is String) {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hours = int.parse(timeParts[0]);
        final minutes = int.parse(timeParts[1]);
        return '${hours}시간 ${minutes}분';
      }
    } else if (time is int) {
      int hours = time ~/ 60;
      int minutes = time % 60;
      return '${hours}시간 ${minutes}분';
    }
    return '0시간 0분'; // 기본값
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8D6E63),
        centerTitle: true,
        title: Text('My School Level'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF8E1),
              const Color(0xFFD7CCC8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Text(
                "<$schoolName>",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/images/school_lv$schoolLevel.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            // 수정된 부분: totalTime에 _formatTime을 적용
            Text(
              "Level : $schoolLevel\n총 누적시간 : ${_formatTime(totalTime)}",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            Text(
              "[획득 메달 정보]",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SchoolMedalList(schoolId: schoolId),  // 매개변수 userId를 MedalList에 전달
                  );
                },
                child: Image.asset(
                  'assets/icon/medal_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 로딩창
void showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 로딩 중 다른 곳 클릭 비활성화
    barrierColor: Colors.white.withOpacity(1), // 전체 화면 반투명 배경
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // 뒤로가기 버튼 비활성화
        child: Align(
          alignment: Alignment.center, // 화면 중앙에 정렬
          child: Container(
            width: MediaQuery.of(context).size.width, // 화면 전체 너비
            height: MediaQuery.of(context).size.height, // 화면 전체 높이
            color: Colors.transparent, // 투명 배경 (barrierColor로 이미 덮음)
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(), // 로딩 스피너
                  SizedBox(height: 10),
                  Text(
                    '로딩 중...',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


void hideLoading(BuildContext context) {
  Navigator.of(context).pop(); // 로딩창 닫기
}
