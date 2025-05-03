import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'; // ✅ foreground task
import 'foreground_task_handler.dart'; // ✅ handler
import 'main.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  final ja.AudioPlayer _bgAudioPlayer = ja.AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();

  final List<String> _messages = [
    '나와 함께 꿈나라로 가자 💫',
    '오늘 하루도 수고했어 ✨',
    '포근한 밤이야 🌙',
    '눈을 감고 쉬어볼까? 😴',
    '이젠 편하게 자도 돼 💫',
  ];
  int _messageIndex = 0;
  late Timer _messageTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration();
  int _alarmRepeatCount = 0;
  final int _maxRepeats = 3;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  bool _isDimmed = false;
  bool _manualDimToggle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startForegroundTask(); // ✅ 포그라운드 태스크 시작

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

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
          FlutterForegroundTask.stopService();
          print('광고 로딩 실패: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _bgAudioPlayer.dispose();
    _alarmPlayer.dispose();
    _messageTimer.cancel();
    _countdownTimer?.cancel();
    _bannerAd.dispose();
    _cancelNotification();
    FlutterForegroundTask.stopService(); // ✅ 포그라운드 태스크 종료
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _startForegroundTask() async {
    final isRunning = await FlutterForegroundTask.isRunningService;

    if (!isRunning) {
      FlutterForegroundTask.startService(
        notificationTitle: '꿈꾸는 고양이',
        notificationText: '영상 재생 중...',
        callback: startCallback,
      );

      print("✅ Foreground Task 실행됨");
    } else {
      print("ℹ️ Foreground Task 이미 실행 중");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
      _bgAudioPlayer.setUrl(widget.videoUrl);
      _bgAudioPlayer.setLoopMode(ja.LoopMode.one);
      _bgAudioPlayer.play();
    } else if (state == AppLifecycleState.resumed) {
      _bgAudioPlayer.stop();
      _controller.play();
      _cancelNotification();
    }
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
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
          _isDimmed = false;
        });
        _alarmRepeatCount = 0;
        _playAlarmRepeatedly();
      } else {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
          if (_remainingTime.inSeconds == 60 * 55 && !_manualDimToggle) {
            _isDimmed = true;
          }
        });
      }
    });
  }

  void _playAlarmRepeatedly() async {
    if (_alarmRepeatCount >= _maxRepeats) return;
    try {
      await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));
      _alarmRepeatCount++;
      Future.delayed(const Duration(seconds: 33), _playAlarmRepeatedly);
    } catch (e) {
      print("🔊 알람 재생 실패: $e");
    }
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final videoHeight = screenWidth * 9 / 16;

    return Stack(
      children: [
        Scaffold(
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
          body: Column(
            children: [
              if (_controller.value.isInitialized)
                SizedBox(
                  width: screenWidth,
                  height: videoHeight,
                  child: VideoPlayer(_controller),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 16),
              Center(child: _buildTimerControls()),
              const SizedBox(height: 30),
              _buildMessageSection(),
            ],
          ),
          bottomNavigationBar: _isBannerAdReady && !isLandscape
              ? Container(
                  color: const Color(0xFF0F172A),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                )
              : null,
        ),
        if (_isDimmed)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.95)),
          ),
        if (!isLandscape)
          Positioned(
            bottom: 80,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 40, 132, 175),
              ),
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
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text("취소"),
                ),
              ),
            ],
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
