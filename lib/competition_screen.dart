import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class CompetitionScreen extends StatefulWidget {
  final String schoolName;
  final int Ranking;
  final int monthlyTotalTime;

  CompetitionScreen({
    required this.schoolName,
    required this.Ranking,
    required this.monthlyTotalTime,
  });

  @override
  _CompetitionScreenState createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  List<Map<String, dynamic>> userContributions = [];

  @override
  void initState() {
    super.initState();
    _fetchSchoolContributions();
  }

  Future<void> _fetchSchoolContributions() async {
    final response = await http.post(
      Uri.parse('http://116.124.191.174:15023/selected-school-competition'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'schoolName': widget.schoolName}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userContributions = List<Map<String, dynamic>>.from(data['contributions']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contributions')),
      );
    }
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

  List<PieChartSectionData> _generateSchoolContributionChart() {
    if (widget.monthlyTotalTime == 0) return [];

    return userContributions.map((user) {
      final userTime = user['monthly_time'] ?? 0;
      final contributionPercent = (userTime / widget.monthlyTotalTime) * 100;
      final color = Colors.primaries[userContributions.indexOf(user) % Colors.primaries.length];
      return PieChartSectionData(
        color: color,
        value: userTime.toDouble(),
        title: '${contributionPercent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Column(
      children: userContributions.map((user) {
        final color = Colors.primaries[userContributions.indexOf(user) % Colors.primaries.length];
        final userTime = user['monthly_time'] ?? 0;
        final contributionPercent = (userTime / widget.monthlyTotalTime) * 100;

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
          subtitle: Text('공부 시간: ${_formatTime(userTime)} - ${contributionPercent.toStringAsFixed(1)}%'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8D6E63),
        centerTitle: true,
        title: Text('${widget.schoolName} 대회 정보'),
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
                '${widget.schoolName}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('순위: ${widget.Ranking}위'),
              SizedBox(height: 10),
              Text('월간 누적 공부 시간: ${_formatTime(widget.monthlyTotalTime)}'),
              SizedBox(height: 20),
              Divider(),
              Text(
                '대회 기여도 분포',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generateSchoolContributionChart(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
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
                    final contributionPercent = (user['monthly_time'] / widget.monthlyTotalTime) * 100;
                    final color = Colors.primaries[userContributions.indexOf(user) % Colors.primaries.length];

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
                          '공부 시간: ${_formatTime(user['monthly_time'])} - ${contributionPercent.toStringAsFixed(1)}%'),
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
}
