// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../main_screen.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  int selectPage = 0;
  PageController controller = PageController();

  List pageArr = [
    {
      "title": "Welcome to Mbrara Grooves",
      "subtitle": "Your home for the best local music and artists.",
      "image": "assets/logo.png",
    },
    {
      "title": "Discover New Hits",
      "subtitle": "Explore curated playlists and find your next favorite song.",
      "image": "assets/logo.png",
    },
    {
      "title": "Listen Anywhere",
      "subtitle":
          "Download your favorite tracks and enjoy your music offline, anytime.",
      "image": "assets/logo.png",
    },
  ];

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      setState(() {
        selectPage = controller.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: controller,
              itemCount: pageArr.length,
              itemBuilder: ((context, index) {
                var pObj = pageArr[index] as Map? ?? {};
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: media.width,
                      height: media.width,
                      alignment: Alignment.center,
                      child: Image.asset(
                        pObj["image"].toString(),
                        width: media.width * 0.65,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: media.width * 0.2),
                    Text(
                      pObj["title"].toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: media.width * 0.05),
                    Text(
                      pObj["subtitle"].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: media.width * 0.20),
                  ],
                );
              }),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: media.height * 0.6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      pageArr.map((e) {
                        var index = pageArr.indexOf(e);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color:
                                index == selectPage
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }).toList(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectPage >= 2) {
                        // Home Screen

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                        );
                      } else {
                        //Next Screen

                        setState(() {
                          selectPage = selectPage + 1;
                          controller.animateToPage(
                            selectPage,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selectPage == pageArr.length - 1 ? 'GET STARTED' : 'NEXT',
                    ),
                  ),
                ),
                SizedBox(height: media.height * 0.05),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
