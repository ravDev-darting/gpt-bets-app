import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gptbets_sai_app/main.dart';
import 'package:http/http.dart' as http;

class MatchDetailsScreen extends StatefulWidget {
  final int gameId;
  final String sport;

  const MatchDetailsScreen(
      {super.key, required this.gameId, required this.sport});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? gameData;
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fetchGameDetails();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _fetchGameDetails() async {
    final endpoint =
        sportToEndpoint[widget.sport] ?? 'v1.baseball.api-sports.io';
    final url = Uri.https(endpoint, '/games', {'id': widget.gameId.toString()});

    final headers = {
      'x-rapidapi-host': endpoint,
      'x-rapidapi-key': key, // Replace with your actual API key
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['response'] != null &&
            responseData['response'].isNotEmpty) {
          setState(() {
            gameData = responseData['response'][0];
            isLoading = false;
            _controller.forward();
          });
        } else {
          setState(() {
            errorMessage = 'No game details found.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load game details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching game details: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF59A52B), Color(0xFF3D7A1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Game Details',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
      body: Padding(
        // Add padding to prevent overflow on the right
        padding: const EdgeInsets.only(right: 18.0),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF59A52B)),
                  ),
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.roboto(
                        color: Colors.redAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildGameInfo(),
                          ),
                          const SizedBox(height: 30),
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildTeamsInfo(),
                          ),
                          const SizedBox(height: 30),
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildScoresInfo(),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${gameData!["game"]["stage"]} - Week ${gameData!["game"]["week"]}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF59A52B),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today,
              'Date: ${gameData!["game"]["date"]["date"]} ${gameData!["game"]["date"]["time"]}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on,
              'Venue: ${gameData!["game"]["venue"]["name"]}, ${gameData!["game"]["venue"]["city"]}'),
          const SizedBox(height: 12),
          _buildInfoRow(
              Icons.info, 'Status: ${gameData!["game"]["status"]["long"]}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF59A52B), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
      children: [
        Expanded(child: _buildTeamCard(gameData!["teams"]["home"])),
        const SizedBox(width: 20), // Add spacing between teams
        Expanded(child: _buildTeamCard(gameData!["teams"]["away"])),
      ],
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFF59A52B).withOpacity(0.2), Colors.transparent],
            ),
          ),
          child: Hero(
            tag: 'team-${team["name"]}',
            child: ClipOval(
              child: Image.network(
                team["logo"],
                width: 120, // Reduced size to prevent overflow
                height: 120,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20), // Increased spacing
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 140), // Limit text width
          child: Text(
            team["name"],
            textAlign: TextAlign.center,
            maxLines: 2, // Allow wrapping if needed
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 18, // Slightly smaller for better fit
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0xFF59A52B).withOpacity(0.3), blurRadius: 4)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresInfo() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scores',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF59A52B),
            ),
          ),
          const SizedBox(height: 16),
          ...[
            _buildScoreRow('Q1', gameData!["scores"]["home"]["quarter_1"],
                gameData!["scores"]["away"]["quarter_1"]),
            _buildScoreRow('Q2', gameData!["scores"]["home"]["quarter_2"],
                gameData!["scores"]["away"]["quarter_2"]),
            _buildScoreRow('Q3', gameData!["scores"]["home"]["quarter_3"],
                gameData!["scores"]["away"]["quarter_3"]),
            _buildScoreRow('Q4', gameData!["scores"]["home"]["quarter_4"],
                gameData!["scores"]["away"]["quarter_4"]),
            _buildScoreRow('OT', gameData!["scores"]["home"]["overtime"],
                gameData!["scores"]["away"]["overtime"]),
            const Divider(color: Colors.white12, height: 24),
            _buildScoreRow('Total', gameData!["scores"]["home"]["total"],
                gameData!["scores"]["away"]["total"],
                isTotal: true),
          ].map((widget) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: widget,
              )),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, dynamic homeScore, dynamic awayScore,
      {bool isTotal = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: isTotal
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF59A52B).withOpacity(0.2),
                  Colors.transparent
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.white : Colors.white70,
            ),
          ),
          Text(
            '${homeScore ?? "-"} - ${awayScore ?? "-"}',
            style: GoogleFonts.robotoMono(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF59A52B) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
