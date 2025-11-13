import 'dart:async';
import 'package:flutter/material.dart';

class EventBannerSlider extends StatefulWidget {
  const EventBannerSlider({super.key});

  @override
  State<EventBannerSlider> createState() => _EventBannerSliderState();
}

class _EventBannerSliderState extends State<EventBannerSlider> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _eventData = [
    {
      'day': '28',
      'weekday': 'Fri',
      'title': 'New Collaboration with Miro',
      'subtitle': 'Miro Inc.',
      'time': '11:00 AM',
      'asset': 'assets/event-png/miro.png',
      'bg': Color.fromARGB(126, 130, 76, 224), // ✅ removed const
      'textColor': Colors.white,
    },
    {
      'day': '30',
      'weekday': 'Sun',
      'title': 'Partnership with Microsoft and AWS',
      'subtitle': 'Microsoft / AWS',
      'time': '02:00 PM',
      'asset': 'assets/event-png/microsoft_aws.png',
      'bg': Color.fromARGB(176, 33, 150, 243), // ✅ removed const
      'textColor': Colors.white,
    },
    {
      'title': 'Happy Birthday 🎂',
      'subtitle': 'May all your wishes come true',
      'asset': 'assets/event-png/cake.png',
      'bg': Color.fromARGB(118, 255, 64, 128), // ✅
      'textColor': Colors.white,
    },
    {
      'title': 'Welcome Onboard 🚀',
      'subtitle': 'Excited to have you with us!',
      'asset': 'assets/event-png/onboarding.png',
      'bg': Color.fromARGB(171, 68, 137, 255), // ✅
      'textColor': Colors.white,
    },
    {
      'title': 'Team Meeting 📅',
      'subtitle': 'Today at 3:00 PM in Zoom',
      'asset': 'assets/event-png/meeting.png',
      'bg': Color.fromARGB(133, 76, 175, 79), // ✅
      'textColor': Colors.white,
    },
    {
      'title': 'Work Anniversary 🎉',
      'subtitle': 'Congrats on 1-year milestone!',
      'asset': 'assets/event-png/anniversary.png',
      'bg': Color.fromARGB(108, 150, 86, 3), // ✅
      'textColor': Colors.white,
    },
    {
      'title': 'Merry Christmas 🎄',
      'subtitle': 'Wishing you joy and peace!',
      'asset': 'assets/event-png/christmas.png',
      'bg': Color.fromARGB(81, 255, 52, 52), // ✅
      'textColor': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _eventData.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _eventData[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey(data['title']),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data['bg'] as Color?,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Text Section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['day'] != null && data['weekday'] != null)
                        Row(
                          children: [
                            Text(
                              '${data['weekday']} ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: data['textColor'],
                              ),
                            ),
                            Text(
                              data['day'],
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: data['textColor'],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Text(
                        data['title'],
                        style: TextStyle(
                          color: data['textColor'],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['subtitle'],
                        style: TextStyle(
                          color: data['textColor'],
                          fontSize: 16,
                        ),
                      ),
                      if (data['time'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '⏰ ${data['time']}',
                            style: TextStyle(
                              color: data['textColor'],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Image Section
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    data['asset'],
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
