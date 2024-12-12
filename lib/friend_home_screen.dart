import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'medal_list.dart';
import 'fullSchool_screen.dart';
import 'home_screen.dart';
class FriendHomeScreen extends StatefulWidget {
  final int friendId;  // 친구의 userId를 매개변수로 받음

  FriendHomeScreen({required this.friendId});

  @override
  _FriendHomeScreenState createState() => _FriendHomeScreenState();
}

class _FriendHomeScreenState extends State<FriendHomeScreen> {
  String schoolName = '';
  String friendNickname = '';
  List<Map<String, dynamic>> placedItems = []; // 배치된 아이템 리스트

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    showLoading(context); // 로딩 창 표시
    try {
      // await Future.delayed(Duration(seconds: 1)); // 지연
      await _fetchFriendNickname();
      _fetchSchoolName();
      _fetchPlacedItems(); // 서버에서 배치된 아이템 가져오기
    } finally {
      hideLoading(context); // 로딩 창 숨기기
    }

  }

  Future<void> _fetchFriendNickname() async {
    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-user-nickname'),  // 서버 API 주소 수정
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'userId': widget.friendId}),  // 친구의 userId로 nickname을 가져옴
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          friendNickname = data['nickname'];  // 친구의 nickname을 상태에 저장
        });
      } else {
        print('Failed to load friend nickname. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching friend nickname: $e');
    }
  }

  Future<void> _fetchSchoolName() async {
    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-user-school-name'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'userId': widget.friendId}),  // 친구의 userId로 학교 이름을 가져옴
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          schoolName = data['school_name'];
        });
      } else {
        print('Failed to load school name. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching school name: $e');
    }
  }

  Future<void> _fetchPlacedItems() async {
    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-placed-items'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'userId': widget.friendId}),  // 친구의 userId로 배치된 아이템 가져옴
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        setState(() {
          // 서버에서 가져온 데이터를 처리하며 크기를 추가
          placedItems = data.map((item) {
            String itemName = item['item_name'];
            double width = 100;
            double height = 100;
            String category = item['category'];

            if (category == '가구') {
              if (itemName.startsWith('책상')) {
                width = 200;
                height = 200;
              } else if (itemName.startsWith('의자')) {
                width = 200;
                height = 200;
                itemName = "${itemName}_뒷"; // 수정된 변수 사용
              }
            } else if (category == '조명' || category == '동물' || category == '식물') {
              width = 100;
              height = 100;
            }

            return {
              'item_name': itemName,
              'x': item['x'],
              'y': item['y'],
              'width': width,
              'height': height,
              'inventory_id': item['inventory_id'],
              'priority': item['priority'], // 우선순위 속성 추가
            };
          }).toList();
        });
        // 우선순위 기준으로 정렬
        placedItems.sort((a, b) => b['priority'].compareTo(a['priority']));
      } else {
        print('Failed to load placed items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching placed items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4E342E),
        centerTitle: true,
        title: GestureDetector(
          // onTap: () {
          //   Navigator.push(context, MaterialPageRoute(builder: (context) => FriendHomeScreen(friendId: widget.friendId)));  // 친구의 홈 화면을 다시 호출
          // },
          child: Text(
            "${friendNickname}'s home",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icon/home_icon.png',
                width: 30,
                height: 30,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 190,
            left: 50,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FullSchoolScreen(userId: widget.friendId)));
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icon/board_icon.png',
                    width: 300,
                    height: 300,
                  ),
                  Positioned(
                    top: 115,
                    child: Text(
                      schoolName,
                      style: TextStyle(
                        fontFamily: 'NeoDGM',
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: 295,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => MedalList(userId: widget.friendId),  // friendId를 MedalList에 전달
                );
              },
              child: Image.asset(
                'assets/icon/medal_icon.png',
                width: 80,
                height: 80,
              ),
            ),
          ),
          // 배치된 아이템들을 화면에 표시
          ...placedItems.map((item) {
            return Positioned(
              top: item['y'].toDouble(),
              left: item['x'].toDouble(),
              child: GestureDetector(
                onTap: () {
                  // 아이템 클릭 시 해당 아이템의 inventory_id로 처리
                  print('Item tapped: ${item['item_name']} with inventory_id: ${item['inventory_id']}');
                  // 여기에서 inventory_id를 사용하여 아이템의 배치 상태 등을 처리할 수 있습니다.
                },
                child: Image.asset(
                  'assets/icon/${item['item_name']}_icon.png',
                  width: item['width'], // 설정된 크기 사용
                  height: item['height'], // 설정된 크기 사용
                ),
              ),
            );
          }).toList(),
        ],
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