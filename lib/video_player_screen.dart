import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';

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
    '나와 함께 꿈나라로 가자 💫',
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

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  bool _isDimmed = false;
  bool _manualDimToggle = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('광고 로딩 실패: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _bannerAd.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
      _isDimmed = false;
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
          if (!_manualDimToggle) _isDimmed = false;
        });
        _alarmRepeatCount = 0;
        _playAlarmRepeatedly();
      } else {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
          if (_remainingTime.inSeconds == 5 * 60 && !_manualDimToggle) {
            _isDimmed = true;
          }
        });
      }
    });
  }

  void _playAlarmRepeatedly() async {
    if (_alarmRepeatCount >= _maxRepeats) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      _alarmRepeatCount++;
      Future.delayed(const Duration(seconds: 33), () {
        _playAlarmRepeatedly();
      });
    } catch (e) {
      print("🔊 알람 재생 실패: $e");
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final spacingSmall = screenHeight * 0.02;
    final spacingLarge = screenHeight * 0.05;

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: isLandscape
              ? null
              : AppBar(
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
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 14.0),
                      child: AspectRatio(
                        aspectRatio: 16 / 12,
                        child: player,
                      ),
                    ),
                  ),
                  SizedBox(height: spacingSmall),
                  Center(child: _buildTimerControls()),
                  SizedBox(height: spacingLarge),
                  _buildMessageSection(),
                ],
              ),
              if (_isDimmed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        '절전모드 중',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isLandscape)
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isDimmed = !_isDimmed;
                        _manualDimToggle = _isDimmed;
                      });
                    },
                    child: Text(_isDimmed ? "절전 해제" : "절전 모드"),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _isBannerAdReady && !isLandscape
              ? Container(
                  color: const Color(0xFF0F172A),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTimerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              "타이머: ${_formatDuration(_remainingTime)}",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildTimerButton("1시간", const Duration(hours: 1)),
              _buildTimerButton("10분", const Duration(minutes: 10)),
              _buildTimerButton("5분", const Duration(minutes: 5)),
              SizedBox(
                width: 75,
                child: ElevatedButton(
                  onPressed: _cancelTimer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  child: const Text("취소"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMessageBubble(),
          _buildBubbleTail(12),
          _buildBubbleTail(6),
          const SizedBox(height: 4),
          Lottie.asset(
            'assets/animations/sleeping_cat.json',
            width: 120,
            height: 120,
            repeat: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton(String label, Duration duration) {
    return SizedBox(
      width: 85,
      child: ElevatedButton(
        onPressed: () => _addTime(duration),
        child: Text(
          label,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Widget _buildBubbleTail(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.lightBlueAccent),
      ),
    );
  }
}
