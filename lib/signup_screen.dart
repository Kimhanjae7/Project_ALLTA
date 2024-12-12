import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  List<String> schoolList = []; // 검색된 학교 리스트

  Future<void> _fetchSchoolList(String query) async {
    if (query.isEmpty) return;

    // 서버에서 학교 목록 검색
    final response = await http.get(
      Uri.parse('http://116.124.191.174:15023/search-schools?query=$query'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> schools = json.decode(response.body);
      setState(() {
        schoolList = schools.map((school) {
          final name = school['school_name'];
          return name == null ? 'Unknown School' : name as String;
        }).toList();
        print('Fetched school list: $schoolList'); // 디버깅 로그 추가
      });
    } else {
      print('Failed to fetch school list: ${response.body}');
    }
  }


  Future<void> _signup() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String nickname = _nicknameController.text;
    String schoolName = _schoolController.text;

    if (email.isEmpty || password.isEmpty || nickname.isEmpty || schoolName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일, 비밀번호, 별명, 학교는 필수입니다')),
      );
      return;
    }

    try {
      // 서버에 POST 요청
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'nickname': nickname,
          'school_name': schoolName,
        }),
      );

      // 응답 처리
      if (response.statusCode == 201) {
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 성공')),
        );
        Navigator.pop(context); // 로그인 화면으로 돌아가기
      } else {
        // 오류 메시지 파싱
        final Map<String, dynamic> responseData = json.decode(response.body);
        String errorMessage = responseData['message'] ?? '회원가입 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      // 네트워크 오류 등 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와 연결할 수 없습니다. 나중에 다시 시도해주세요.')),
      );
    }
  }

  void _showSchoolSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _schoolController,
                          decoration: InputDecoration(
                            labelText: 'Search School',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          // 검색 버튼을 누르면 학교 리스트를 갱신
                          await _fetchSchoolList(_schoolController.text);
                          modalState(() {}); // 모달 상태 새로고침
                        },
                        child: Text('검색'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: schoolList.isEmpty
                        ? Center(
                      child: Text('No schools found'), // 검색 결과 없음
                    )
                        : ListView.builder(
                      itemCount: schoolList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(schoolList[index]),
                          onTap: () {
                            setState(() {
                              _schoolController.text = schoolList[index];
                            });
                            Navigator.pop(context); // 검색 창 닫기
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 159, 138, 130), // 브라운 톤의 색상으로 변경
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 22, // 원하는 경우 폰트 크기 추가
            color: Colors.black, // 원하는 경우 폰트 색상 추가
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.jpg'), // 로그인과 동일한 배경 이미지
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), // 반투명 배경색 설정
                    borderRadius: BorderRadius.circular(10), // 모서리 둥글게 설정
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: TextStyle(color: Colors.white),
                        obscureText: true,
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: 'Nickname',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _schoolController,
                        readOnly: true,
                        onTap: _showSchoolSearch, // 학교 검색 창 호출
                        decoration: InputDecoration(
                          labelText: 'School (tap to search)',
                          labelStyle: TextStyle(color: Colors.white70),
                          suffixIcon: Icon(Icons.search, color: Colors.white70),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signup,
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
