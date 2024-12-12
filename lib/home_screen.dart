import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timer_screen.dart';
import 'rank_screen.dart';
import 'store_sidebar.dart';
import 'chest_sidebar.dart';
import 'fullSchool_screen.dart';
import 'friends_screen.dart';
import 'medal_list.dart';
import 'dart:convert';
import 'dart:async'; // Timer를 사용하려면 이 패키지가 필요합니다.
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAnimalDrawer = false;
  int userId = 1;
  String schoolName = '';
  List<Map<String, dynamic>> placedItems = [];
  bool hasNewNotifications = false;
  List<Map<String, dynamic>> notifications = [];

  // Timer 변수 추가
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      // 5초마다 데이터를 새로고침하는 타이머 시작
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        _fetchNotifications();
      });
    });
  }

  @override
  void dispose() {
    // 페이지가 dispose될 때 타이머를 취소
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    showLoading(context); // 로딩 창 표시
    try {
      // await Future.delayed(Duration(seconds: 1)); // 지연
      await _fetchUserId();
      _fetchSchoolName();
      _fetchPlacedItems();
      _fetchNotifications();
    } finally {
      hideLoading(context); // 로딩 창 숨기기
    }
  }


  void toggleStoreDrawer() {
    setState(() {
      isAnimalDrawer = !isAnimalDrawer;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scaffold.of(context).openEndDrawer();
    });
  }

  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId') ?? 1;
      print('userId = ${userId}');
    });
  }

  Future<void> _fetchSchoolName() async {
    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-user-school-name'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          schoolName = data['school_name'];
        });
        print('Successfully loaded school name: $schoolName');
      } else {
        print('Failed to load school name. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
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
        body: json.encode({'userId': userId}),
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

        print('Placed items loaded: $placedItems');
      } else {
        print('Failed to load placed items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching placed items: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {});
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RankScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => TimerScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendsScreen()));
        break;
    }
  }

  // ChestSidebar를 BottomSheet로 호출하는 함수
  void _showChestSidebar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChestSidebar(
        userId: userId,
      ),
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/get-notifications'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        setState(() {
          notifications = data.where((item) => item['is_read'] == 0).map((item) {
            return {
              'id': item['notification_id'],
              'message': item['message'],
              'is_read': item['is_read'],
            };
          }).toList();
          hasNewNotifications = notifications.isNotEmpty;
        });
        print('Notifications fetched: $notifications');
      } else {
        print('Failed to fetch notifications. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // 기존 코드에서 _markNotificationAsRead 수정하기
  Future<void> _markNotificationAsRead(int notificationId) async {
    // null 체크 추가
    if (notificationId == null) {
      print("Invalid notification ID");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/mark-notification-read'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'notificationId': notificationId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((notification) => notification['id'] == notificationId);
          hasNewNotifications = notifications.isNotEmpty;
        });
        print('Notification $notificationId marked as read.');
      } else {
        print('Failed to mark notification as read. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }


  void _showNotificationPopup(BuildContext context, GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: (offset?.dy ?? 0),
              right: MediaQuery.of(context).size.width - (offset?.dx ?? 0) - 40,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: notifications.isEmpty
                      ? Center(
                    child: Text(
                      "알림이 없습니다.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                      : SizedBox(
                    height: notifications.length > 4 ? 120 : null,
                    child: Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return GestureDetector(
                            onTap: () async {
                              // null 체크 추가
                              final notificationId = notification['id'];
                              if (notificationId == null) {
                                print("Invalid notification ID");
                                return;
                              }

                              await _markNotificationAsRead(notificationId);
                              Navigator.of(context).pop(); // 팝업 닫기
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Icon(Icons.notifications, color: Colors.brown, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      notification['message'] ?? "알림 메세지가 없습니다.",
                                      style: TextStyle(fontSize: 14, color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    GlobalKey notificationButtonKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4E342E),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'assets/icon/chest_icon.png',
            width: 30,
            height: 30,
          ),
          onPressed: _showChestSidebar,
        ),
        title: GestureDetector(
          // onTap: () {
          //   Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          // },
          child: Text(
            'All Time',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icon/shop_icon.png',
                width: 30,
                height: 30,
              ),
              onPressed: () {
                setState(() {
                  isAnimalDrawer = !isAnimalDrawer;
                });
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: StoreSidebar(
        isAnimalDrawer: isAnimalDrawer,
        onToggleDrawer: toggleStoreDrawer,
        userId: userId,
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => FullSchoolScreen(userId: userId)));
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
              onTap: () async {
                if (userId != null) {
                  showDialog(
                    context: context,
                    builder: (context) => MedalList(userId: userId),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User ID not found')),
                  );
                }
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
          Positioned(
            top: 20,
            right: 20,
            child: Stack(
              children: [
                IconButton(
                  key: notificationButtonKey,
                  icon: Icon(Icons.notifications, color: Colors.brown, size: 30),
                  onPressed: () => _showNotificationPopup(context, notificationButtonKey),
                ),
                if (hasNewNotifications)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 115,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/ranking_icon.png',
                          width: 90,
                          height: 90,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/timer_icon2.png',
                          width: 90,
                          height: 90,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/friend_icon.png',
                          width: 80,
                          height: 80,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
