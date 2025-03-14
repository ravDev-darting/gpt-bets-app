import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gptbets_sai_app/main.dart';
import 'package:http/http.dart' as http;

class SportsPage extends StatefulWidget {
  final String sport;
  const SportsPage({super.key, required this.sport});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> latestGames = [];
  List<dynamic> upcomingGames = [];
  List<dynamic> standings = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  DateTime selectedDate = DateTime.now(); // Added for date picker

  final Map<String, String> sportToEndpoint = {
    'NFL & NCAA': 'v1.american-football.api-sports.io',
    'NBA & NCAA': 'v2.nba.api-sports.io',
    'MLB': 'v1.baseball.api-sports.io',
    'NASCAR & F1': 'v1.formula-1.api-sports.io',
    'MMA': 'v1.mma.api-sports.io',
    'NHL': 'v1.hockey.api-sports.io',
    'Soccer': 'v3.football.api-sports.io',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _fetchRecord();
    _fetchStandings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Date picker method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF59A52B),
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      _fetchRecord();
      _fetchStandings();
    }
  }

  _fetchRecord() async {
    print('Fetching data for ${widget.sport}...');

    final endpoint =
        sportToEndpoint[widget.sport] ?? 'v1.baseball.api-sports.io';
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final url = Uri.https(
      endpoint,
      '/games',
      widget.sport.toString().contains('NBA')
          ? {'season': selectedDate.year.toString()}
          : {'date': formattedDate, 'season': selectedDate.year.toString()},
    );

    final headers = {
      'x-rapidapi-host': endpoint,
      'x-rapidapi-key': key, // Replace with your actual API key
    };

    try {
      final response = await http.get(url, headers: headers);
      print('API Response for games: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed Data: $responseData');

        if (responseData['response'] != null) {
          setState(() {
            latestGames = responseData['response']
                .where((game) => game['status']?['short'] == 'FT')
                .toList();
            upcomingGames = responseData['response']
                .where((game) => game['status']?['short'] != 'FT')
                .toList();
            isLoading = false;
          });
          print('Latest Games: $latestGames');
          print('Upcoming Games: $upcomingGames');
        } else {
          setState(() {
            errorMessage = 'No games found in the API response.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load data: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  _fetchStandings() async {
    final endpoint =
        sportToEndpoint[widget.sport] ?? 'v1.baseball.api-sports.io';

    final url = Uri.https(
      endpoint,
      '/standings',
      {'league': '1', 'season': selectedDate.year.toString()},
    );

    final headers = {
      'x-rapidapi-host': endpoint,
      'x-rapidapi-key': key, // Replace with your actual API key
    };

    try {
      final response = await http.get(url, headers: headers);
      print('Standings API Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed Standings Data: $responseData');

        if (responseData['response'] != null) {
          setState(() {
            standings = responseData['response'];
            isLoading = false;
          });
          print('Standings: $standings');
        } else {
          setState(() {
            errorMessage = 'No standings found in the API response.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load standings: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching standings: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF59A52B),
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          elevation: 8,
          title: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                '${widget.sport} Hub',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () => _selectDate(context),
            ),
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF59A52B),
            indicatorWeight: 4,
            labelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 14),
            tabs: const [
              Tab(text: 'Games'),
              Tab(text: 'Standings'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF59A52B),
                Colors.grey[900]!,
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Selected Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            backgroundColor: Colors.grey[700],
                          ),
                        )
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                                errorMessage,
                                style: GoogleFonts.roboto(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : TabBarView(
                              children: [
                                _buildUpcomingGamesTable(context),
                                widget.sport == 'Soccer'
                                    ? _buildSoccerStandingsTable()
                                    : _buildStandingsTable(),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingGamesTable(BuildContext context) {
    if (upcomingGames.isEmpty) {
      return Center(
        child: Text(
          'No games found.',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: upcomingGames.length,
      itemBuilder: (context, index) {
        final game = upcomingGames[index];
        print('Game: $game');
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset((1 - _controller.value) * 50, 0),
              child: Opacity(
                opacity: _controller.value,
                child: Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      "${game['teams']['home']['name']} vs ${game['teams']['away']['name']}",
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "${game['game']['date']['date']} - ${game['game']['date']['time']}",
                      style: GoogleFonts.roboto(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStandingsTable() {
    if (standings.isEmpty) {
      return Center(
        child: Text(
          'No standings found.',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final standing = standings[index];
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.95 + (_controller.value * 0.05),
              child: Opacity(
                opacity: _controller.value,
                child: Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(standing['team']['logo']),
                    ),
                    title: Text(
                      standing['team']['name'],
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "W: ${standing['won']} L: ${standing['lost']} T: ${standing['ties']}",
                      style: GoogleFonts.roboto(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59A52B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Pts: ${standing['points']['for']}",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSoccerStandingsTable() {
    if (standings.isEmpty) {
      return Center(
        child: Text(
          'No standings found.',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final league = standings[index]['league'];
        final groups = standings[index]['standings'];

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _controller.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${league['name']} - ${league['season']}',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...groups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            'Group ${group[0]['group']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ...group.map((team) {
                          return Card(
                            color: Colors.grey[850],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    NetworkImage(team['team']['logo']),
                              ),
                              title: Text(
                                team['team']['name'],
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                "Rank: ${team['rank']} | Pts: ${team['points']} | GD: ${team['goalsDiff']}",
                                style: GoogleFonts.roboto(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF59A52B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  team['form'],
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class GameDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF59A52B),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 8,
        title: Text(
          'Game Details',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Matchup: ${game['teams']['home']['name']} vs ${game['teams']['away']['name']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow("Date:", game['game']['date']['date']),
                _buildDetailRow("Time:", game['game']['date']['time']),
                _buildDetailRow("Score:",
                    "${game['scores']['home']['total']} : ${game['scores']['away']['total']}"),
                _buildDetailRow("Status:", game['status']['long']),
                const SizedBox(height: 20),
                _buildDetailRow("Venue:", game['game']['venue']['name']),
                _buildDetailRow("City:", game['game']['venue']['city']),
                const SizedBox(height: 20),
                Text(
                  "Players:",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Team A: Player 1, Player 2, Player 3",
                  style: GoogleFonts.roboto(
                    color: Colors.grey[300],
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Team B: Player 4, Player 5, Player 6",
                  style: GoogleFonts.roboto(
                    color: Colors.grey[300],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF59A52B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
