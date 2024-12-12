import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      // 서버에 POST 요청
      final response = await http.post(
        Uri.parse('http://116.124.191.174:15023/login'), // 서버 주소
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // 로그인 성공 시 환영 메시지 표시
        final jsonResponse = json.decode(response.body);
        final nickname = jsonResponse['nickname']; // 서버에서 nickname 가져오기
        final message = '$nickname님, 환영합니다!';

        // 사용자 ID를 shared preferences에 저장
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setInt('userId', jsonResponse['user_id']); // user_id를 int로 저장

        // 로그인 성공 후 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        // 로그인 성공 시 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (response.statusCode == 401) {
        // 로그인 실패 시 경고 메시지 (아이디 또는 비밀번호 오류)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('아이디나 비밀번호가 존재하지 않습니다')),
        );
      } else if(response.statusCode == 400){
        // 로그인 실패 시 경고 메시지 (아이디 또는 비밀번호 오류)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json.decode(response.body)['message'])),
        );
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일과 비밀번호를 입력하세요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 159, 138, 130), // 브라운 톤의 색상으로 변경
        title: const Text(
          'ALLTA',
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
            image: AssetImage('assets/images/login_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(50, 30, 50, 30),
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
                          labelStyle: TextStyle(color: Colors.white70), // 라벨 색상 변경
                        ),
                        style: TextStyle(color: Colors.white), // 입력 텍스트 색상 변경
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white70), // 라벨 색상 변경
                        ),
                        style: TextStyle(color: Colors.white), // 입력 텍스트 색상 변경
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: Text('Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}