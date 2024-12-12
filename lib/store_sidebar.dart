import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoreSidebar extends StatefulWidget {
  final bool isAnimalDrawer;
  final VoidCallback onToggleDrawer;
  final int userId;

  StoreSidebar({
    required this.isAnimalDrawer,
    required this.onToggleDrawer,
    required this.userId,
  });

  @override
  _StoreSidebarState createState() => _StoreSidebarState();
}

class _StoreSidebarState extends State<StoreSidebar> {
  String? selectedCategory;
  int userPoints = 0;
  List<Map<String, dynamic>> items = []; // Store fetched items

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/getUserPoints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userPoints = data['points'] ?? 0;
      });
    } else {
      print("Failed to load user points");
    }
  }

  Future<void> _fetchItemsByCategory(String category) async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/getItemsByCategory'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'category': category}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      });
    } else {
      print("Failed to load items for category: $category");
    }
  }

  void _purchaseItem(int itemId, String itemName, int price) async {
    if (userPoints >= price) {
      // 사용자 포인트가 충분할 경우
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/purchaseItem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'item_id': itemId,
          'item_price': price,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          userPoints -= price; // 로컬에서 포인트 업데이트
        });

        // 구매 완료 팝업 띄우기
        _showPurchaseResultDialog('$itemName 구매가 완료되었습니다!', Colors.green);
      } else {
        // 구매 실패 팝업 띄우기
        _showPurchaseResultDialog('구매 중 문제가 발생했습니다. 다시 시도해주세요.', Colors.red);
      }
    } else {
      // 포인트 부족 시
      _showPurchaseResultDialog('포인트가 부족합니다!', Colors.red);
    }
  }

void _showPurchaseResultDialog(String message, Color backgroundColor) {
  showDialog(
    context: context,
    barrierDismissible: false, // 팝업 외부를 클릭해도 닫히지 않도록 설정
    builder: (context) {
      // 팝업이 뜨고 1.5초 후 자동으로 사라지게 설정
      Future.delayed(Duration(seconds: 1, milliseconds: 500), () {
        Navigator.of(context).pop(); // 1.5초 후 팝업 닫기
      });

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 팝업 모서리를 둥글게
        ),
        backgroundColor: Color(0xFFFFF8E1), // 따뜻한 베이지 톤 배경
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[700], // 성공 표시를 초록색으로
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                message, // 성공 메시지
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown, // 브라운 톤 텍스트 색상
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}




  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            color: Colors.brown[100],
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.brown[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '보유 포인트',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$userPoints',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              child: selectedCategory == null
                  ? _buildMainStoreDrawer()
                  : _buildCategoryDrawer(selectedCategory!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStoreDrawer() {
    return Column(
      children: [
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.pets, color: Colors.orange),
          title: Text('동물', style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            setState(() {
              selectedCategory = '동물';
            });
            _fetchItemsByCategory('동물');
          },
        ),
        ListTile(
          leading: Icon(Icons.local_florist, color: Colors.green),
          title: Text('식물', style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            setState(() {
              selectedCategory = '식물';
            });
            _fetchItemsByCategory('식물');
          },
        ),
        ListTile(
          leading: Icon(Icons.chair, color: Colors.brown),
          title: Text('가구', style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            setState(() {
              selectedCategory = '가구';
            });
            _fetchItemsByCategory('가구');
          },
        ),
        ListTile(
          leading: Icon(Icons.lightbulb, color: Colors.yellow[700]),
          title: Text('조명', style: TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            setState(() {
              selectedCategory = '조명';
            });
            _fetchItemsByCategory('조명');
          },
        ),
        Spacer(),
        BackButton(
          color: Colors.brown,
          onPressed: Navigator.of(context).pop,
        ),
        SizedBox(height: 10),
      ],
    );
  }

Widget _buildCategoryDrawer(String category) {
  if (items.isEmpty) {
    return Center(child: CircularProgressIndicator());
  }

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '$category 카테고리',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2개의 열로 구성된 그리드
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9, // 자식 요소의 가로:세로 비율 조정
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                _showPurchaseDialog(item['item_id'], item['item_name'], item['price']);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 221), // 배경색 설정
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                  border: Border.all(
                    color: Colors.brown, // 테두리 색상
                    width: 2, // 테두리 두께
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // 그림자 색상
                      blurRadius: 4, // 그림자 흐림 정도
                      offset: Offset(2, 2), // 그림자 위치
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/icon/${item['item_name']}_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 2), // 이미지와 텍스트 사이 간격
                    Text(
                      item['item_name'], // 아이템 이름 표시
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 0.5),
                    Text(
                      '${item['price']} 포인트', // 가격 표시
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 0.5),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      BackButton(
        color: Colors.brown,
        onPressed: () {
          setState(() {
            selectedCategory = null;
          });
        },
      ),
      SizedBox(height: 10),
    ],
  );
}




  void _showPurchaseDialog(int itemId, String itemName, int price) {
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
            '${itemName}을(를) 구매하시겠습니까?',
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
              'assets/icon/${itemName}_icon.png', // 아이템 이미지를 팝업에 추가
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 10),
            Text(
              '가격: $price 포인트',
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                      color: Colors.black87, // 버튼 텍스트 색상
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    backgroundColor: Color(0xFFD7A87E), // 구매 버튼 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _purchaseItem(itemId, itemName, price); // 구매 버튼
                  },
                  child: Text(
                    '구매',
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
        ],
      );
    },
  );
}

}
