import 'package:flutter/material.dart';
import 'package:gptbets_sai_app/sportsPage.dart';

class Sportshub extends StatefulWidget {
  const Sportshub({super.key});

  @override
  State<Sportshub> createState() => _SportshubState();
}

class _SportshubState extends State<Sportshub> {
  final List<Map<String, dynamic>> sports = [
    {'name': 'NFL', 'icon': Icons.sports_football},
    {'name': 'NBA', 'icon': Icons.sports_basketball},
    {'name': 'MLB', 'icon': Icons.sports_baseball},
    {'name': 'NCAA Basketball', 'icon': Icons.sports_basketball},
    {'name': 'MMA', 'icon': Icons.sports_martial_arts},
    {'name': 'NHL', 'icon': Icons.sports_hockey},
    {'name': 'Soccer', 'icon': Icons.sports_soccer},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            color: Color(0xFF9CFF33), // Custom green for the icon
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)), // Back button
        title: Text(
          'Sports Hub',
          style: TextStyle(
            color: Color(0xFF9CFF33), // Custom green for the title
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Color(0xFF9CFF33).withOpacity(0.8),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black, // Black app bar
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black, // Black at the top
              Colors.grey[900]!, // Dark grey at the bottom
            ],
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: sports.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Color(0xFF9CFF33).withOpacity(0.3),
                color: Colors.grey[850], // Dark grey card background
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SportsPage(sport: sports[index]['name'])));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!.withOpacity(0.8),
                          Colors.grey[800]!.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF9CFF33).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with neon glow
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return RadialGradient(
                                center: Alignment.center,
                                radius: 1.0,
                                colors: [
                                  Color(0xFF9CFF33).withOpacity(0.9),
                                  Color(0xFF9CFF33).withOpacity(0.2),
                                ],
                                stops: [0.0, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child: Icon(
                              sports[index]['icon'],
                              size: 56,
                              color: Color(0xFF9CFF33), // Custom green icon
                            ),
                          ),
                          SizedBox(height: 12),
                          // Text with neon glow
                          Text(
                            sports[index]['name'],
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF9CFF33), // Custom green text
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF9CFF33).withOpacity(0.8),
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
