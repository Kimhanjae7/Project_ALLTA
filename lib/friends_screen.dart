import 'friend_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  TextEditingController _controller = TextEditingController();
  int? _userId;
  List<dynamic> _friendRequests = [];
  List<dynamic> _friends = [];
  Map<String, dynamic>? _searchedUser;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    if (_userId != null) {
      _fetchFriendRequests();
      _fetchFriends();
    }
  }

  Future<void> _searchUser(String nickname) async {
    if (nickname.isEmpty) {
      _showPopup('닉네임을 입력해주세요.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://116.124.191.174:15023/search-user?nickname=$nickname'),
      );

      if (response.statusCode == 200) {
        final user = json.decode(response.body);
        setState(() {
          _searchedUser = user;
        });
        // 검색 성공 팝업 제외
      } else if (response.statusCode == 404) {
        _showPopup('사용자를 찾을 수 없습니다.');
      } else {
        final error = json.decode(response.body);
        _showPopup(error['message'] ?? '검색에 실패했습니다.');
      }
    } catch (e) {
      _showPopup('오류가 발생했습니다: $e');
    }
  }

  Future<void> _sendFriendRequest(int friendId) async {
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/send-friend-request'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'userId': _userId,
          'friendNickname': _searchedUser!['nickname'],
        }),
      );

      if (response.statusCode == 200) {
        _showPopup('친구 요청이 성공적으로 전송되었습니다.');
      } else {
        final error = json.decode(response.body);
        _showPopup(error['message'] ?? '친구 요청에 실패했습니다.');
      }
    } catch (e) {
      _showPopup('오류가 발생했습니다: $e');
    }
  }

  Future<void> _acceptFriendRequest(int friendshipId) async {
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/accept-friend-request'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'friendshipId': friendshipId}),
      );

      if (response.statusCode == 200) {
        _showPopup('친구 요청을 수락했습니다.');
        _fetchFriends();
        _fetchFriendRequests();
      } else {
        final error = json.decode(response.body);
        _showPopup(error['message'] ?? '친구 요청 수락에 실패했습니다.');
      }
    } catch (e) {
      _showPopup('오류가 발생했습니다: $e');
    }
  }

  Future<void> _rejectFriendRequest(int friendshipId) async {
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/reject-friend-request'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'friendshipId': friendshipId}),
      );

      if (response.statusCode == 200) {
        _showPopup('친구 요청을 거절했습니다.');
        _fetchFriendRequests();
      } else {
        final error = json.decode(response.body);
        _showPopup(error['message'] ?? '친구 요청 거절에 실패했습니다.');
      }
    } catch (e) {
      _showPopup('오류가 발생했습니다: $e');
    }
  }

  Future<void> _fetchFriendRequests() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://116.124.191.174:15023/friend-requests/$_userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _friendRequests = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching friend requests: $e');
    }
  }

  Future<void> _fetchFriends() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://116.124.191.174:15023/friends/$_userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _friends = json.decode(response.body);
        });
      } else {
        print('Failed to fetch friends. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
  }

  void _showPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 팝업 테두리 둥글게
        ),
        backgroundColor: Colors.brown[50], // 팝업 배경색
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.brown, size: 24), // 타이틀 아이콘 추가
            SizedBox(width: 8),
            Text(
              '알림',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800], // 타이틀 텍스트 색상
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.brown[700], // 메시지 텍스트 색상
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.brown, // 버튼 배경색
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // 버튼 모양 둥글게
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                color: Colors.white, // 버튼 텍스트 색상
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        backgroundColor: Color(0xFF8D6E63),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              SizedBox(height: 20),
              if (_searchedUser != null) _buildSearchedUserSection(),
              SizedBox(height: 20),
              if (_friendRequests.isNotEmpty) _buildFriendRequestsSection(),
              SizedBox(height: 20),
              if (_friends.isNotEmpty) _buildFriendsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        style: TextStyle(
          fontSize: 16,
          color: Colors.brown[700],
        ),
        decoration: InputDecoration(
          labelText: '닉네임 검색',
          labelStyle: TextStyle(
            color: Colors.brown,
            fontSize: 14,
          ),
          hintText: '검색어를 입력하세요',
          hintStyle: TextStyle(
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.brown,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.brown,
            ),
            onPressed: () {
              _searchUser(_controller.text);
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.brown,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.brown[200]!,
              width: 1,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchedUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '검색된 사용자: ${_searchedUser!['nickname']}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (_searchedUser != null) {
              _sendFriendRequest(_searchedUser!['user_id']);
            }
          },
          child: Text(
            '친구 요청 보내기',
            style: TextStyle(color: Colors.black),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8D6E63),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구 요청 목록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10), // 간격 추가
        ..._friendRequests.map((request) {
          return Card(
            color: const Color.fromARGB(255, 238, 231, 230), // 카드 배경색
            margin: EdgeInsets.symmetric(vertical: 8), // 카드 간 간격
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 모서리 둥글게
            ),
            elevation: 2, // 그림자 효과
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.brown,
                    radius: 15,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  SizedBox(width: 15), // 아이콘과 텍스트 사이 간격
                  Expanded(
                    child: Text(
                      request['nickname'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _acceptFriendRequest(request['friendship_id']),
                      ),
                      SizedBox(width: 8), // 버튼 간 간격
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: () =>
                            _rejectFriendRequest(request['friendship_id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }



  Widget _buildFriendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구 목록',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return Card(
                  color: const Color.fromARGB(255, 238, 231, 230),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.brown,
                          radius: 30,
                          child:
                          Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        SizedBox(height: 3),
                        Text(
                          friend['nickname'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendHomeScreen(
                                    friendId: friend['friend_id']),
                              ),
                            );
                          },
                          child: Text(
                            '교실 보기',
                            style:
                            TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8D6E63),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
