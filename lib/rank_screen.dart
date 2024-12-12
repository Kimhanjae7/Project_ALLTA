import 'package:flutter/material.dart';
import 'contribution_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'schooldetail_screen.dart';
import 'competition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RankScreen extends StatefulWidget {
  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _schoolRankings = [];
  Map<String, dynamic>? _mySchool;
  String userEmail = ''; // 사용자 이메일 변수
  List<String> competitions = ['랭킹', '전국 대회', '지역 대회']; // 대회 이름 리스트
  int currentTabIndex = 0; // 현재 탭 인덱스
  List<String> _locals = []; // 지역 목록
  String? _selectedLocal; // 선택된 지역

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
      _fetchUserEmail();
      _fetchLocals(); // 지역 목록을 가져옵니다
    } finally {
      hideLoading(context); // 로딩 창 숨기기
    }
  }

  Future<void> _fetchUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? '';
    });

    if (userEmail.isNotEmpty) {
      _fetchRankings(currentTabIndex); // 초기 데이터 로드
    }
  }

  // 지역 목록을 가져오는 함수
  Future<void> _fetchLocals() async {
    final response = await http.get(Uri.parse('http://116.124.191.174:15023/school-local'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _locals = [...List<String>.from(data)];
        _selectedLocal = '서울'; // 초기값을 '전체'로 설정
        _selectedLocal = _locals[0]; // 맨 위에 있는 값으로 초기화
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load local')),
      );
    }
  }

  // 특정 대회의 랭킹 데이터를 가져오는 함수
  Future<void> _fetchRankings(int tabIndex) async {
    String competitionName = competitions[tabIndex];

    setState(() {
      _mySchool = null;
      _schoolRankings = [];
    });

    // 서버에 요청하여 내 학교 정보를 가져옵니다
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/get-school-name'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userEmail': userEmail}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String mySchoolName = data['school_name'];

      // 지역 대회에서 지역이 선택되었으면, 지역 정보를 URL에 추가
      String url = 'http://116.124.191.174:15023/school-rankings?competition=$competitionName';
      if (competitionName == '지역 대회' && _selectedLocal != null && _selectedLocal!.isNotEmpty) {
        url += '&local=$_selectedLocal';
      }
      print('Requesting URL: $url');

      // 대회별 랭킹 데이터를 가져옵니다
      final rankingsResponse = await http.get(Uri.parse(url));

      if (rankingsResponse.statusCode == 200) {
        final List<dynamic> rankingsData = json.decode(rankingsResponse.body);
        print(rankingsData);  // 전체 데이터 출력

        setState(() {
          _schoolRankings = rankingsData.map((item) => {
            'school_name': item['school_name'],
            'total_ranking': item['total_ranking'],
            'monthly_ranking': item['monthly_ranking'],
            'local_ranking': item['local_ranking'],
            'total_time': item['total_time'],
            'monthly_total_time': item['monthly_total_time'],
            'level': item['school_level'],
            'local': item['school_local'],
          }).toList();

          // '랭킹', '전국 대회' 탭인 경우에만 내 학교를 포함
          if (competitionName == '랭킹' || competitionName == '전국 대회') {
            _mySchool = _schoolRankings.firstWhere(
                  (school) => school['school_name'] == mySchoolName,
              orElse: () => <String, dynamic>{},
            );
          } else {
            _mySchool = null; // '지역 대회' 탭에서는 내 학교를 제거
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rankings for $competitionName')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch school name')),
      );
    }
  }

  String getImageForLevel(int? level) {
    level = level ?? 1;
    return 'assets/images/school_lv$level.png';
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
    return '0시간 0분';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: competitions.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF8D6E63),
          centerTitle: true,
          title: Text('School Ranking'),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                currentTabIndex = index;
                print("Selected Tab: $index, Competition: ${competitions[index]}");
              });
              _fetchRankings(index);
            },
            tabs: competitions.map((comp) => Tab(text: comp)).toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
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
              children: [
                if (currentTabIndex == 2) // '지역 대회' 탭에서만 드롭다운 표시
                  DropdownButton<String>(
                    value: _selectedLocal,
                    hint: Text("지역 선택"),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLocal = newValue;
                      });
                      _fetchRankings(currentTabIndex); // 선택된 지역으로 데이터 재요청
                    },
                    items: _locals.map((String _local) {
                      return DropdownMenuItem<String>(
                        value: _local,
                        child: Text(_local),
                      );
                    }).toList(),
                  ),
                if (_mySchool != null && _mySchool!.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ContributionScreen(
                              isTotalTime: currentTabIndex == 0,
                          )),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Image.asset(
                                getImageForLevel(_mySchool!['level']),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentTabIndex == 0
                                        ? "${_mySchool!['total_ranking']}위 ${_mySchool!['school_name']}"
                                        : currentTabIndex == 1
                                        ? "${_mySchool!['monthly_ranking']}위 ${_mySchool!['school_name']}"
                                        : "${_mySchool!['local_ranking']}위 ${_mySchool!['school_name']}",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    currentTabIndex == 0
                                        ? "총 누적시간: ${_formatTime(_mySchool!['total_time'])}"
                                        : "월별 총 누적시간: ${_formatTime(_mySchool!['monthly_total_time'])}",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _schoolRankings.length,
                    itemBuilder: (context, index) {
                      final school = _schoolRankings[index];
                      return GestureDetector(
                        onTap: () {
                          if (currentTabIndex == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SchoolDetailScreen(
                                  schoolName: school['school_name'],
                                  totalRanking: school['total_ranking'],
                                  totalTime: school['total_time'],
                                ),
                              ),
                            );
                          } else if (currentTabIndex == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompetitionScreen(
                                  schoolName: school['school_name'],
                                  Ranking: school['monthly_ranking'],
                                  monthlyTotalTime: school['monthly_total_time'],
                                ),
                              ),
                            );
                          } else if (currentTabIndex == 2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompetitionScreen(
                                  schoolName: school['school_name'],
                                  Ranking: school['local_ranking'],
                                  monthlyTotalTime: school['monthly_total_time'],// 지역 랭킹 전달
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          elevation: 5.0,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: Image.asset(
                              getImageForLevel(school['level']),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            title: Text(school['school_name']),
                            subtitle: Text(currentTabIndex == 0
                                ? "총 누적시간: ${_formatTime(school['total_time'])}"
                                : "월별 총 누적시간: ${_formatTime(school['monthly_total_time'])}",),
                            trailing: Text(currentTabIndex == 0
                                ? "${school['total_ranking']}위"
                                : currentTabIndex == 1
                                ? "${school['monthly_ranking']}위"
                                : "${school['local_ranking']}위"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
