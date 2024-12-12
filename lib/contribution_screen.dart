import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class ContributionScreen extends StatefulWidget {
  final bool isTotalTime;  // isTotalTime 값을 받아옵니다.

  ContributionScreen({required this.isTotalTime});  // 생성자에서 값 전달

  @override
  _ContributionScreenState createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  String schoolName = '';
  String ranking = '';
  int total_time = 0;
  List<Map<String, dynamic>> userContributions = [];
  String userEmail = '';
  String userNickname = '';
  int userContributionTime = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
    });

    if (userEmail.isNotEmpty) {
      await _fetchContributions();
    }
  }

  Future<void> _fetchContributions() async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/school-contributions'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userEmail': userEmail,
        'isTotalTime': widget.isTotalTime,  // isTotalTime 값을 서버로 전달
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        schoolName = data['schoolName'];
        ranking = data['ranking'].toString();
        total_time = data['total_time'];
        userContributions = List<Map<String, dynamic>>.from(data['contributions']);

        userNickname = data['userNickname'];
        final user = userContributions.firstWhere(
              (contribution) => contribution['nickname'] == userNickname,
          orElse: () => {'total_time': 0, 'nickname': 'N/A'},
        );
        userContributionTime = user['total_time'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contributions')),
      );
    }
  }

  String _formatTime(int time) {
    int hours = time ~/ 60;
    int minutes = time % 60;
    return '${hours}시간 ${minutes}분';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8D6E63),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          child: Text('Contributions'),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$schoolName',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('순위: $ranking위'),
              SizedBox(height: 10),
              Text('총 공부 시간: ${_formatTime(total_time)}'),
              SizedBox(height: 20),
              Divider(),
              Text(
                '내 기여도',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generateChartSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2, // 섹션 사이에 공간 추가
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              Text(
                '사용자별 기여도',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: userContributions.isEmpty
                    ? Center(child: Text('현재 학교에 속한 사용자가 없습니다.'))
                    : ListView.builder(
                  itemCount: userContributions.length,
                  itemBuilder: (context, index) {
                    final user = userContributions[index];
                    final contributionPercent = (user['total_time'] / total_time) * 100;
                    final color = user['nickname'] == userNickname
                        ? Color.fromARGB(255, 112, 88, 79) // 본인 기여도의 색상
                        : Color.fromARGB(135, 255, 255, 255); // 다른 사용자 기여도의 색상

                    return ListTile(
                      title: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: color,
                          ),
                          SizedBox(width: 8),
                          Text('${user['nickname']}'),
                        ],
                      ),
                      subtitle: Text(
                          '공부 시간: ${_formatTime(user['total_time'])} - ${contributionPercent.toStringAsFixed(1)}%'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateChartSections() {
    if (total_time == 0) return [];
    final userPercentage = (userContributionTime / total_time) * 100;
    final remainingPercentage = 100 - userPercentage;

    return [
      PieChartSectionData(
        color: Color.fromARGB(255, 112, 88, 79),
        value: userContributionTime.toDouble(),
        title: '${userPercentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color.fromARGB(135, 255, 255, 255),
        value: (total_time - userContributionTime).toDouble(),
        title: '${remainingPercentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    ];
  }
}
