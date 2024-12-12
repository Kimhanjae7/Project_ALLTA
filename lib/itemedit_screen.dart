import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'chest_sidebar.dart';

class ItemEditScreen extends StatefulWidget {
  @override
  _ItemEditScreenState createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  bool isAnimalDrawer = false;
  int userId = 1;
  String schoolName = '';
  List<Map<String, dynamic>> placedItems = []; // 배치된 아이템 리스트
  String? selectedItem;

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
      await _fetchUserId();
      _fetchPlacedItems(); // 서버에서 배치된 아이템 가져오기
    } finally {
      hideLoading(context); // 로딩 창 숨기기
    }
  }

  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId') ?? 1;
      print('userId = $userId');
    });
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

  void _removeItem(Map<String, dynamic> item) async {
    setState(() {
      placedItems.removeWhere((i) => i['item_name'] == item['item_name']);
      selectedItem = null; // 선택된 아이템 초기화
    });

    // 서버에서 아이템 배치 해제 요청
    try {
      await http.post(
        Uri.parse('http://116.124.191.174:15023/remove-item'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'user_id': userId,
          'inventory_id': item['inventory_id'],
        }),
      );

      print('Removed item: ${item['item_name']} by userId: $userId, inventory_id: ${item['inventory_id']}');
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> _updateItemPosition(Map<String, dynamic> item) async {
    try {
      await http.post(
        Uri.parse('http://116.124.191.174:15023/update-item-position'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'user_id': userId,
          'item_name': item['item_name'],
          'x': item['x'],
          'y': item['y'],
          'inventory_id': item['inventory_id'], // inventory_id 추가
          'priority': 0, // 우선순위 속성 추가
        }),
      );
      // 로컬 데이터 우선순위 업데이트
      setState(() {
        item['priority'] = 0; // 현재 아이템을 최상위로 설정
        for (var otherItem in placedItems) {
          if (otherItem['item_name'] != item['item_name']) {
            otherItem['priority'] = (otherItem['priority'] ?? 0) + 1;
          }
        }

        // 우선순위 내림차순 정렬
        placedItems.sort((a, b) => b['priority'].compareTo(a['priority']));
      });

      print('Updated position for ${item['item_name']}: x=${item['x']}, y=${item['y']}, priority=${item['priority']}');
    } catch (e) {
      print('Error updating item position: $e');
    }
  }

  // 중앙으로 아이템 위치 초기화
  void _resetItemsToCenter() {
    setState(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      for (var item in placedItems) {
        item['x'] = screenWidth / 2 - 25; // 화면 중앙으로 X 좌표 설정
        item['y'] = screenHeight / 2 - 25; // 화면 중앙으로 Y 좌표 설정
        _updateItemPosition(item); // 서버 업데이트
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4E342E),
        centerTitle: true,
        title: Text(
          'Edit Items',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icon/chest_icon.png',
            width: 30,
            height: 30,
          ),
          onPressed: _showChestSidebar,
        ),
      ),
      body: GestureDetector(
        // 빈 곳 클릭 이벤트 처리
        onTap: () {
          setState(() {
            selectedItem = null; // 선택 상태 해제
          });
        },
        child: Stack(
          children: [
            // 배경 이미지
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/home_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 배치된 아이템들
            ...placedItems.map((item) {
              final bool isSelected = selectedItem == item['item_name'];

              return Positioned(
                top: item['y'].toDouble(),
                left: item['x'].toDouble(),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedItem = item['item_name'];
                    });
                  },
                  child: Draggable<Map<String, dynamic>>(
                    data: item,
                    feedback: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: Image.asset(
                        'assets/icon/${item['item_name']}_icon.png',
                        width: item['width'],
                        height: item['height'],
                      ),
                    ),
                    childWhenDragging: SizedBox.shrink(),
                    onDraggableCanceled: (velocity, offset) {
                      setState(() {
                        // 마우스 위치에 아이템이 정확히 위치하도록 변경
                        item['x'] = offset.dx - 0; // 마우스 위치를 기준으로 아이템의 X 좌표 조정
                        item['y'] = offset.dy - 75; // 마우스 위치를 기준으로 아이템의 Y 좌표 조정
                      });
                      _updateItemPosition(item);
                    },
                    onDragUpdate: (details) {
                      setState(() {
                        item['x'] = details.localPosition.dx - 25; // 마우스 위치를 기준으로 아이템의 위치를 조정
                        item['y'] = details.localPosition.dy - 25; // 마우스 위치를 기준으로 아이템의 위치를 조정
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 아이템 이미지
                          Image.asset(
                            'assets/icon/${item['item_name']}_icon.png',
                            width: item['width'],
                            height: item['height'],
                          ),
                          // X 버튼 (선택된 아이템만 표시)
                          if (isSelected)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: GestureDetector(
                                onTap: () {
                                  _removeItem(item);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            // "수정 완료" 버튼
            Positioned(
              bottom: 80, // 위치 초기화 버튼 위에 배치
              right: 20,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()), // HomeScreen으로 이동
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done, color: Colors.white), // 아이콘 추가
                      SizedBox(width: 8),
                      Text(
                        '수정 완료',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // "위치 초기화" 버튼
            Positioned(
              bottom: 20, // 수정 완료 버튼 아래에 배치
              right: 20,
              child: InkWell(
                onTap: _resetItemsToCenter, // 위치 초기화 동작
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white), // 아이콘 추가
                      SizedBox(width: 8),
                      Text(
                        '위치 초기화',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
