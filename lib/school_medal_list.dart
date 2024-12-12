import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'medal_popup.dart';

class SchoolMedalList extends StatefulWidget {
  final int schoolId; // 학교 ID를 전달받음

  SchoolMedalList({required this.schoolId});

  @override
  _MedalListState createState() => _MedalListState();
}

class _MedalListState extends State<SchoolMedalList> {
  late Future<List<Map<String, dynamic>>> medalList;

  @override
  void initState() {
    super.initState();
    medalList = fetchMedals(widget.schoolId); // 학교 ID로 메달 목록을 가져옴
  }

  Future<List<Map<String, dynamic>>> fetchMedals(int schoolId) async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/get-school-medals'), // API 변경
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'schoolId': schoolId}), // schoolId 전달
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .where((medal) => medal['medal_id'] != null && medal['ranking'] != null)
          .map((medal) => {
        'medal_id': medal['medal_id'],
        'ranking': medal['ranking'].toString(),
        'battle_inf': medal['battle_inf'].replaceAll('월 ','월\n'),
      })
          .toList();
    } else {
      throw Exception('Failed to load medals');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8D6E63), // 브라운 톤의 색상으로 변경
        centerTitle: true,
        title: Text('School Medal List'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFD7CCC8),
            ],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(  // 학교 메달 목록
          future: medalList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              var medals = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                itemCount: medals.length,
                itemBuilder: (context, index) {
                  var medal = medals[index];
                  var medalId = medal['medal_id'];
                  var ranking = medal['ranking'];
                  var battleInf = medal['battle_inf'];

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => MedalPopup(
                          queryType: 'school', // 학교 메달
                          schoolId: widget.schoolId, // 학교 ID
                          medalId: medalId, // 메달 ID
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: Colors.brown.withOpacity(0.5),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF3E5AB), Color(0xFFBCAAA4)],
                          ),
                          image: DecorationImage(
                            image: AssetImage('assets/icon/medal_icon.png'),
                            alignment: Alignment.centerRight,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.5),
                              BlendMode.dstATop,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(left: 30, right: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$battleInf $ranking등', // 제목 변경
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4E342E),
                                  letterSpacing: 1.2, // 글자 간격 조정
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Click to view medal details',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(
                child: Text(
                  'No medals available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
