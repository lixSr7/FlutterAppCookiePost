import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

Future<List> fetchData() async {
  final response = await http
      .get(Uri.parse('https://cookie-beta-post-mobile-m5j8.onrender.com/post'));

  if (response.statusCode == 200) {
    print('Data successfully recovered');
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load data');
  }
}

class MyRowData {
  final String domain;
  final int measure;
  final Color color;

  MyRowData(this.domain, this.measure, this.color);
}

class MyChart extends StatelessWidget {
  final List<ColumnSeries<MyRowData, String>> seriesList;
  final bool animate;

  MyChart(this.seriesList, {this.animate = false});

  @override
  Widget build(BuildContext context) {
    return new SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(interval: 10),
      series: seriesList,
    );
  }
}

class DisabledPostsPieChart extends StatelessWidget {
  final List data;

  DisabledPostsPieChart(this.data);

  @override
  Widget build(BuildContext context) {
    var disabledPostsCount =
        data.where((post) => post['Post']['IsDisable']).length;
    var enabledPostsCount = data.length - disabledPostsCount;

    var chartData = [
      {'status': 'Inhabilitado', 'count': disabledPostsCount},
      {'status': 'Habilitado', 'count': enabledPostsCount},
    ];

    var colors = [
      Colors.red[300]!,
      Colors.blue[200]!,
    ];

    return Row(
      children: [
        Expanded(
          child: SfCircularChart(
            series: <CircularSeries>[
              PieSeries<dynamic, String>(
                dataSource: chartData,
                xValueMapper: (datum, index) => datum['status'],
                yValueMapper: (datum, index) => datum['count'],
                pointColorMapper: (datum, index) =>
                    colors[index % colors.length],
                dataLabelSettings: DataLabelSettings(isVisible: false),
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Porcentaje de Posts Habilitados vs Inhabilitados',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'De las ${data.length} publicaciones, '
                '${((enabledPostsCount / data.length) * 100).toStringAsFixed(2)}% están habilitadas y '
                '${((disabledPostsCount / data.length) * 100).toStringAsFixed(2)}% están inhabilitadas.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  bool _isDarkTheme = false;

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Post Page'),
    Text('Users Page'),
    Text('Chats Page'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cookie Beta for Stadistics ',
      theme: _isDarkTheme
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black)
          : ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _isDarkTheme ? Colors.black : Colors.white,
          title: Text('Cookie'),
          actions: [
            IconButton(
              icon:
                  Icon(_isDarkTheme ? Icons.brightness_7 : Icons.brightness_3),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: FutureBuilder<List>(
          future: fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.hasData) {
                var groupedData = <String, int>{};
                var postsWithImages = 0;
                for (var item in snapshot.data!) {
                  var nickname = item['NickName'];
                  groupedData[nickname] = (groupedData[nickname] ?? 0) + 1;
                  if (item['Post']['ImageURL'] != null) {
                    postsWithImages += 1;
                  }
                }

                var sortedKeys = groupedData.keys.toList(growable: false)
                  ..sort((k1, k2) =>
                      (groupedData[k2] ?? 0).compareTo(groupedData[k1] ?? 0));
                LinkedHashMap<String, int> sortedData =
                    LinkedHashMap.fromIterable(
                  sortedKeys,
                  key: (k) => k,
                  value: (k) => groupedData[k]!,
                );

                var top5Data = sortedData.keys.take(5).toList();
                var colors = [
                  Colors.red[300]!,
                  Colors.green[200]!,
                  Colors.blue[200]!,
                  Colors.purple[200]!,
                  Colors.yellow[200]!,
                ];

                var data = top5Data
                    .asMap()
                    .map((index, item) => MapEntry(
                        index,
                        MyRowData(item, groupedData[item]!,
                            colors[index % colors.length])))
                    .values
                    .toList();

                var seriesList = [
                  ColumnSeries<MyRowData, String>(
                    dataSource: data,
                    xValueMapper: (MyRowData post, _) => post.domain,
                    yValueMapper: (MyRowData post, _) => post.measure,
                    pointColorMapper: (MyRowData post, _) => post.color,
                  )
                ];

                var percentageWithImages =
                    (postsWithImages / snapshot.data!.length) * 100;

                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          child: Card(
                            color: _isDarkTheme
                                ? const Color(0xFF111111)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    child: Text(
                                      'Vistazo Rápido a las Posts',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _isDarkTheme
                                              ? Colors.white
                                              : Colors.black),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    child: Text(
                                      'En promedio, un usuario realiza ${((groupedData.values.reduce((a, b) => a + b)) / groupedData.length).toStringAsFixed(2)} Posts',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _isDarkTheme
                                              ? Colors.grey[300]
                                              : Colors.grey[700]),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    child: Text(
                                      'El porcentaje de Posts con imágenes es ${percentageWithImages.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _isDarkTheme
                                              ? Colors.grey[300]
                                              : Colors.grey[700]),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Card(
                          color: _isDarkTheme
                              ? const Color(0xFF111111)
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 150,
                                  child: MyChart(seriesList),
                                ),
                                Text(
                                  'Top 5 de usuarios con más publicaciones realizadas',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkTheme
                                          ? Colors.white
                                          : Colors.black),
                                  textAlign: TextAlign.justify,
                                ),
                                Text(
                                  'Los usuarios con más publicaciones son: ${top5Data.join(', ')}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _isDarkTheme
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          child: Card(
                            color: _isDarkTheme
                                ? const Color(0xFF111111)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 150,
                                    child:
                                        DisabledPostsPieChart(snapshot.data!),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        color: Colors.blue[200],
                                      ),
                                      SizedBox(width: 5),
                                      Text('Habilitado'),
                                      SizedBox(width: 15),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        color: Colors.red[300],
                                      ),
                                      SizedBox(width: 5),
                                      Text('Inhabilitado'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          elevation: 0,
          backgroundColor: _isDarkTheme ? Colors.black : Colors.white,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isDarkTheme
                      ? const Color(0xFF111111)
                      : const Color.fromARGB(255, 243, 243, 243),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.post_add),
              ),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isDarkTheme
                      ? const Color(0xFF111111)
                      : const Color.fromARGB(255, 243, 243, 243),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people),
              ),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isDarkTheme
                      ? const Color(0xFF111111)
                      : const Color.fromARGB(255, 243, 243, 243),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat),
              ),
              label: 'Chats',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF9353D3),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
