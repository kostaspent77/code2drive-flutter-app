import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPage extends StatelessWidget {
  final List<Map<String, String>> videos = [
    {
      "title": "DMV Practice Test 2023 Study Guide",
      "url": "https://www.youtube.com/watch?v=4RxOGhEr_5E",
      "image": "assets/VIDEO1.png"
    },
    {
      "title": "Roundabouts Driving Lesson",
      "url": "https://www.youtube.com/watch?v=_NeEF1fwT4k",
      "image": "assets/VIDEO2.png"
    },
    {
      "title": "Learn How to Drive Class 101",
      "url": "https://www.youtube.com/watch?v=aT61nwd5U-s",
      "image": "assets/VIDEO3.png"
    },
  ];

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Watch and learn!",
        style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return GestureDetector(
            onTap: () => _launchURL(video["url"]!),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        video["image"]!,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        video["title"]!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
