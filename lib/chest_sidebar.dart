import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'itemedit_screen.dart';

class ChestSidebar extends StatefulWidget {
  final int userId;

  ChestSidebar({
    required this.userId,
  });

  @override
  _ChestSidebarState createState() => _ChestSidebarState();
}

class _ChestSidebarState extends State<ChestSidebar> {
  String selectedCategory = '전체'; // 기본값 '전체'
  List<Map<String, dynamic>> userItems = [];  // inventory_id 포함한 아이템 목록

  @override
  void initState() {
    super.initState();
    _fetchUserItems(); // 아이템을 가져옵니다.
  }

  // 카테고리 값도 함께 보내도록 수정
  Future<void> _fetchUserItems() async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/getUserItems'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'category': selectedCategory, // 선택된 카테고리 추가
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        // 배치되지 않은 아이템만 리스트에 저장
        userItems = List<Map<String, dynamic>>.from(data['items']
            .where((item) => item['is_placed'] == 0) // is_placed가 0인 아이템만 포함
            .map((item) {
          return {
            'item_name': item['item_name'],
            'inventory_id': item['inventory_id'],
          };
        }));
      });
    } else {
      print("Failed to load user items");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 카테고리 버튼 (전체, 가구 등)
                Text(
                  '인벤토리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    backgroundColor: Colors.brown[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // ItemEditScreen으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ItemEditScreen()),
                    );
                  },
                  child: Text(
                    '배치 편집',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // 카테고리 버튼을 Row로 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton('전체', Icons.all_inclusive, Colors.blue),
              _buildCategoryButton('가구', Icons.chair, Colors.brown),
              _buildCategoryButton('조명', Icons.lightbulb, Colors.yellow[700]!),
              _buildCategoryButton('식물', Icons.local_florist, Colors.green),
              _buildCategoryButton('동물', Icons.pets, Colors.orange),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 255, 255, 221),
                    const Color.fromARGB(255, 212, 158, 124),
                  ],
                ),
              ),
              child: _buildCategoryView(), // 필터링된 아이템을 표시
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category; // 카테고리 선택
        });
        _fetchUserItems(); // 선택된 카테고리에 맞는 아이템 가져오기
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 4),
          Text(
            category,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView() {
    // 카테고리에 맞는 아이템 리스트를 출력
    return userItems.isEmpty
        ? Center(
      child: Text(
        '해당 카테고리에 아이템이 없습니다',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    )
        : Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 한 줄에 3개의 아이템 표시
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: userItems.length,
        itemBuilder: (context, index) {
          final item = userItems[index];
          String imagePath = 'assets/icon/${item['item_name']}_icon.png'; // 아이템에 맞는 이미지 경로 생성

          return GestureDetector(
            onTap: () {
              // 아이템 클릭 시 배치하기/취소 다이얼로그를 띄움
              _showPlacementDialog(item['item_name'], item['inventory_id']);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath, // 동적으로 생성된 이미지 경로
                    height: 40, // 이미지 크기 조정
                    width: 40,
                    fit: BoxFit.cover, // 이미지 크기에 맞게 자르기
                  ),
                  SizedBox(height: 5),
                  Text(
                    item['item_name'],
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 배치하기/취소 다이얼로그
  void _showPlacementDialog(String item, int inventoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFF8E1), // 따뜻한 베이지 톤 배경
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 팝업창 모서리를 둥글게
          ),
          title: Center(
            child: Text(
              '이 아이템을 배치하시겠습니까?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown, // 브라운 톤 텍스트 색상
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/${item}_icon.png', // 아이템 이미지를 팝업에 추가
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),
              Text(
                '$item을 배치하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // 텍스트 강조
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 버튼을 양쪽 끝에 배치
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      backgroundColor: Color(0xFFD7A87E), // 배치하기 버튼 색상
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await _updateItemIsPlaced(item, inventoryId);  // 아이템 배치 업데이트
                      Navigator.of(context).pop();  // 다이얼로그 닫기
                      // ItemEdit 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemEditScreen(),  // ItemEdit 페이지로 이동
                        ),
                      );
                    },
                    child: Text(
                      '배치',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      backgroundColor: Colors.grey[300], // 취소 버튼 색상
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // 취소 버튼
                    },
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 서버에 배치 상태 업데이트
  Future<void> _updateItemIsPlaced(String item, int inventoryId) async {
    print('Updating item for user_id: ${widget.userId}, inventory_id: $inventoryId, item_name: $item');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double x = screenWidth / 2 - 25;
    double y = screenHeight / 2 - 25;

    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/updateItemIsPlaced'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'inventory_id': inventoryId,  // inventory_id 전달
        'x': x,
        'y': y,
      }),
    );

    if (response.statusCode == 200) {
      print('$item의 is_placed가 1로 업데이트되었습니다.');
    } else {
      print('Failed to update item');
    }
  }
}
