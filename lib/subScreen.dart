import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Subscreen extends StatefulWidget {
  const Subscreen({super.key});

  @override
  State<Subscreen> createState() => _SubscreenState();
}

class _SubscreenState extends State<Subscreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              )),
          title: Text('Subscription Plans',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: Color(0xFF59A52B),
          centerTitle: true,
          elevation: 5,
          shadowColor: Colors.black54,
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  PlanCard(
                    title: 'Monthly Plan',
                    price: '\$30.00',
                    features: [
                      'CPTBETS Assistant Model.',
                      'CPTBETS Prediction Model.',
                      'Live Odds and insights across all Bookmakers.',
                      'Automatic Feature Updates when new versions become available.',
                    ],
                    buttonText: 'BUY NOW',
                  ),
                  SizedBox(height: 16),
                  PlanCard(
                    title: 'Yearly Plan',
                    price: '\$250.00 Per Year',
                    features: [
                      'GPTBETS Assistant Model.',
                      'GPTBETS Prediction Model.',
                      'Live Odds and insights across all Bookmakers.',
                      'Automatic Feature Updates when new versions become available.',
                    ],
                    buttonText: 'BUY NOW',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final String buttonText;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF59A52B).withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF59A52B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF59A52B), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Add your buy now logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF59A52B),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black45,
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
