import 'package:flutter/material.dart';

class data {
  static final getData = {
    1: {
      'ingredient': 'Placeholders',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'emoji': '👍'
    },
    2: {
      'ingredient': 'wheat',
      'description': 'Provides structure. Source of gluten.',
      'emoji': '🌾'
    },
    3: {
      'ingredient': 'salt',
      'description':
          'Acts as a preservative by altering the availability of water.',
      'emoji': '🧂'
    }
  };
}

class ResultScreen extends StatelessWidget {
  final String text;
  final _data = data.getData;

  ResultScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                return Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 0),
                    child: Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: const Color(0xFFFFFFFF),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    10, 10, 10, 10),
                                child: Text(
                                  _data[index]!['emoji']!,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                _data[index]!['ingredient']!,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontFamily: 'Poppins',
                                ),
                              )
                            ],
                          ), // d
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10, 0, 0, 20),
                            child: Text(
                              _data[index]!['description']!,
                              style: const TextStyle(
                                  fontSize: 17, fontFamily: 'Poppins'),
                            ),
                          )
                        ],
                      ),
                    ));
              },
            ))
          ],
        ),
      );
}