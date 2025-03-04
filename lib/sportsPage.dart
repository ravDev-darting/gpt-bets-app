import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gptbets_sai_app/main.dart';
import 'package:http/http.dart' as http;

class SportsPage extends StatefulWidget {
  final String sport;
  const SportsPage({super.key, required this.sport});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> {
  List<dynamic> latestGames = [];
  List<dynamic> upcomingGames = [];
  List<dynamic> standings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRecord();
    _fetchStandings();
  }

  _fetchRecord() async {
    print('Fetching data for ${widget.sport}...');
    final url = Uri.https('v1.american-football.api-sports.io', '/games', {});

    // Headers
    final headers = {
      'x-rapidapi-host': 'v1.american-football.api-sports.io',
      'x-rapidapi-key': key, // Replace with your API key
    };

    try {
      // Make the GET request
      final response = await http.get(url, headers: headers);

      // Print the API response for debugging
      print('API Response: ${response.body}');

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final responseData = jsonDecode(response.body);

        // Debug: Print the parsed data
        print('Parsed Data: $responseData');

        // Check if the response contains the expected data
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

          // Debug: Print the filtered games
          print('Latest Games: $latestGames');
          print('Upcoming Games: $upcomingGames');
        } else {
          setState(() {
            errorMessage = 'No games found in the API response.';
            isLoading = false;
          });
        }
      } else {
        // Handle errors
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
    final url = Uri.https(
      widget.sport.contains('NFL')
          ? 'v1.american-football.api-sports.io'
          : 'v2.nba.api-sports.io',
      '/standings',
      {'league': '1', 'season': '2022'},
    );

    // Headers
    final headers = {
      'x-rapidapi-host': 'v1.american-football.api-sports.io',
      'x-rapidapi-key': key, // Replace with your API key
    };

    try {
      // Make the GET request
      final response = await http.get(url, headers: headers);

      // Print the API response for debugging
      print('Standings API Response: ${response.body}');

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final responseData = jsonDecode(response.body);

        // Debug: Print the parsed data
        print('Parsed Standings Data: $responseData');

        // Check if the response contains the expected data
        if (responseData['response'] != null) {
          setState(() {
            standings = responseData['response'];
            isLoading = false;
          });

          // Debug: Print the standings
          print('Standings: $standings');
        } else {
          setState(() {
            errorMessage = 'No standings found in the API response.';
            isLoading = false;
          });
        }
      } else {
        // Handle errors
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
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFF59A52B),
        appBar: AppBar(
          title: Text('NFL Hub'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Latest Games'),
              Tab(text: 'Upcoming Games'),
              Tab(text: 'Standings'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child:
                        Text(errorMessage, style: TextStyle(color: Colors.red)))
                : TabBarView(
                    children: [
                      _buildLatestGamesTable(context),
                      _buildUpcomingGamesTable(context),
                      _buildStandingsTable(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLatestGamesTable(BuildContext context) {
    if (latestGames.isEmpty) {
      return Center(
        child: Text('No latest games found.',
            style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: latestGames.length,
      itemBuilder: (context, index) {
        final game = latestGames[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(
                "${game['teams']['home']['name']} vs ${game['teams']['away']['name']}",
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
                "${game['game']['date']['date']} - ${game['scores']['home']['total']} : ${game['scores']['away']['total']}",
                style: TextStyle(color: Colors.grey)),
            trailing: Text(game['status']['short'],
                style: TextStyle(color: Colors.green)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailsScreen(game: game),
                  ));
            },
          ),
        );
      },
    );
  }

  Widget _buildUpcomingGamesTable(BuildContext context) {
    if (upcomingGames.isEmpty) {
      return Center(
        child: Text('No upcoming games found.',
            style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: upcomingGames.length,
      itemBuilder: (context, index) {
        final game = upcomingGames[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(
                "${game['teams']['home']['name']} vs ${game['teams']['away']['name']}",
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
                "${game['game']['date']['date']} - ${game['game']['date']['time']}",
                style: TextStyle(color: Colors.grey)),
          ),
        );
      },
    );
  }

  Widget _buildStandingsTable() {
    if (standings.isEmpty) {
      return Center(
        child:
            Text('No standings found.', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final standing = standings[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(standing['team']['logo']),
            ),
            title: Text(standing['team']['name'],
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
                "W: ${standing['won']} L: ${standing['lost']} T: ${standing['ties']}",
                style: TextStyle(color: Colors.grey)),
            trailing: Text("Points: ${standing['points']['for']}",
                style: TextStyle(color: Colors.green)),
          ),
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
      appBar: AppBar(
        title: Text('Game Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Matchup: ${game['teams']['home']['name']} vs ${game['teams']['away']['name']}",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            SizedBox(height: 10),
            Text("Date: ${game['game']['date']['date']}",
                style: TextStyle(color: Colors.grey)),
            Text("Time: ${game['game']['date']['time']}",
                style: TextStyle(color: Colors.grey)),
            Text(
                "Score: ${game['scores']['home']['total']} : ${game['scores']['away']['total']}",
                style: TextStyle(color: Colors.grey)),
            Text("Status: ${game['status']['long']}",
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            Text("Venue: ${game['game']['venue']['name']}",
                style: TextStyle(color: Colors.white)),
            Text("City: ${game['game']['venue']['city']}",
                style: TextStyle(color: Colors.white)),
            SizedBox(height: 20),
            Text("Players:",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            Text("Team A: Player 1, Player 2, Player 3",
                style: TextStyle(color: Colors.grey)),
            Text("Team B: Player 4, Player 5, Player 6",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
