import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final List<String> _messages = [
    '나와 함께 꿈나라로 가자 💤',
    '오늘 하루도 수고했어 ✨',
    '포근한 밤이야 🌙',
    '눈을 감고 쉬어볼까? 😴',
    '이젠 편하게 자도 돼 💫',
  ];
  int _messageIndex = 0;
  late Timer _messageTimer;

  Duration _remainingTime = const Duration();
  Timer? _countdownTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _alarmRepeatCount = 0;
  final int _maxRepeats = 3;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addTime(Duration duration) {
    setState(() {
      _remainingTime += duration;
    });
    _startTimer();
  }

  void _cancelTimer() {
    setState(() {
      _remainingTime = Duration.zero;
    });
    _countdownTimer?.cancel();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
        });
        _alarmRepeatCount = 0;
        _playAlarmRepeatedly();
      } else {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _playAlarmRepeatedly() async {
    if (_alarmRepeatCount >= _maxRepeats) return;

    await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    _alarmRepeatCount++;

    Future.delayed(const Duration(seconds: 33), () {
      _playAlarmRepeatedly();
    });
  }

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String hours = duration.inHours.toString().padLeft(2, '0');
    return "$hours:$minutes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),

        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 14.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "타이머: ${_formatDuration(_remainingTime)}",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        child: ElevatedButton(
                          onPressed: () => _addTime(const Duration(hours: 1)),
                          child: const Text("1시간"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: ElevatedButton(
                          onPressed:
                              () => _addTime(const Duration(minutes: 10)),
                          child: const Text("10분"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: ElevatedButton(
                          onPressed: () => _addTime(const Duration(minutes: 5)),
                          child: const Text("5분"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: _cancelTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 말풍선 본체
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.lightBlueAccent),
                    ),
                    child: Text(
                      _messages[_messageIndex],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // 첫 번째 꼬리 원형
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.lightBlueAccent,
                      ), // 테두리 추가
                    ),
                  ),

                  // 두 번째 꼬리 원형 (더 작게!)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.lightBlueAccent,
                      ), // 테두리 추가
                    ),
                  ),

                  const SizedBox(height: 4), // 고양이와의 간격
                  Lottie.asset(
                    'assets/animations/sleeping_cat.json',
                    width: 120,
                    height: 120,
                    repeat: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        color: const Color(0xFF1E293B),
      ),
    );
  }
}
