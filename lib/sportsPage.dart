import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class SportsPage extends StatefulWidget {
  final String sport;
  const SportsPage({super.key, required this.sport});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> games = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  DateTime selectedDate = DateTime.now();
  Duration timeUntilNextUpdate = Duration.zero;
  DateTime? nextUpdateTime;

  final Map<String, String> sportToKey = {
    'NFL': 'americanfootball_nfl',
    'NBA': 'basketball_nba',
    'MLB': 'baseball_mlb',
    'NCAA Football': 'americanfootball_ncaaf',
    'MMA': 'mma_mixed_martial_arts',
    'NHL': 'icehockey_nhl',
    'Soccer': 'soccer_epl',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _fetchOdds();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              primary: Color(0xFF9CFF33),
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
        errorMessage = ''; // Clear error message on new date selection
      });
      _fetchOdds();
    }
  }

  Future<void> _fetchOdds() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Clear error message before retrying
    });

    final sportKey = sportToKey[widget.sport] ?? 'americanfootball_nfl';
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}T12:00:00Z";

    // Check internet connectivity before making request
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage = 'No internet connection. Please check your connection.';
        isLoading = false;
      });
      return;
    }

    final url = Uri.https(
      'api.the-odds-api.com',
      '/v4/historical/sports/$sportKey/odds/',
      {
        'apiKey': '02fe6e8734f74f7547654e87da0ac7e4',
        'regions': 'us',
        'markets': 'h2h',
        'oddsFormat': 'american',
        'date': formattedDate,
      },
    );

    try {
      final response = await http.get(url);
      log('Fetching odds from: $url');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          games = responseData['data'] ?? [];
          nextUpdateTime = responseData['next_timestamp'] != null
              ? DateTime.parse(responseData['next_timestamp'])
              : DateTime.now().add(const Duration(minutes: 5));
          timeUntilNextUpdate = nextUpdateTime!.difference(DateTime.now());
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'No internet connection. Please check your connection.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'No internet connection. Please check your connection.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFF9CFF33),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Color(0xFF9CFF33)),
          backgroundColor: Colors.grey[900],
          elevation: 8,
          title: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                '${widget.sport} Odds',
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchOdds,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF9CFF33), Colors.grey[900]!],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Selected Date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                      style: GoogleFonts.montserrat(
                          color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.wifi_off,
                                      color: Colors.redAccent,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Connection Error',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      errorMessage,
                                      style: GoogleFonts.roboto(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchOdds,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF9CFF33),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : games.isEmpty
                              ? Center(
                                  child: Text(
                                    'No games found for selected date.',
                                    style: GoogleFonts.roboto(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                )
                              : _buildGamesList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final commenceTime = DateTime.parse(game['commence_time']);
        final bookmakers = game['bookmakers'] as List? ?? [];

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
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${game['home_team']} vs ${game['away_team']}",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Starts: ${commenceTime.toLocal()}",
                          style: GoogleFonts.roboto(
                              color: Colors.grey[300], fontSize: 14),
                        ),
                      ],
                    ),
                    children: [
                      if (bookmakers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No bookmaker data available',
                            style: GoogleFonts.roboto(color: Colors.white70),
                          ),
                        )
                      else
                        ...bookmakers.map((bookmaker) {
                          final markets = bookmaker['markets'] as List? ?? [];
                          final h2hMarket = markets.firstWhere(
                            (m) => m['key'] == 'h2h',
                            orElse: () => null,
                          );

                          if (h2hMarket == null) return const SizedBox();

                          final outcomes = h2hMarket['outcomes'] as List;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                ...outcomes.map((outcome) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            outcome['name'],
                                            style: GoogleFonts.roboto(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: outcome['price'] > 0
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            outcome['price'].toString(),
                                            style: GoogleFonts.robotoMono(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(color: Colors.grey),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
