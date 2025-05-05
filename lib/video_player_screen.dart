import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ 추가
import 'main.dart'; // ✅ flutterLocalNotificationsPlugin 가져오기 위해 import
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'foreground_task_handler.dart'; // startCallback이 정의된 파일

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

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        WakelockPlus.enable();
        _controller.setLooping(true);
      });

    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7625356414808879/3876215538',
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
    try {
      WakelockPlus.disable();
    } catch (e) {
      print('Wakelock 해제 중 오류: $e');
    }
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _bgAudioPlayer.dispose();
    _alarmPlayer.dispose();
    _messageTimer.cancel();
    _countdownTimer?.cancel();
    _bannerAd.dispose();
    _cancelNotification(); // ✅ 종료 시 알림 끄기
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
      _bgAudioPlayer.setUrl(widget.videoUrl);
      _bgAudioPlayer.setLoopMode(ja.LoopMode.one);
      _bgAudioPlayer.play();
      _showNotification(); // ✅ 백그라운드 진입 시 알림 표시
    } else if (state == AppLifecycleState.resumed) {
      _bgAudioPlayer.stop();
      _controller.play();
      _cancelNotification(); // ✅ 복귀 시 알림 제거
    } else if (state == AppLifecycleState.detached) {
      _cancelNotification(); // ✅ 완전 종료 시 알림 제거 시도
    }
  }

  Future<void> _showNotification() async {
    await FlutterForegroundTask.startService(
      notificationTitle: '꿈꾸는 고양이',
      notificationText: '영상 재생 중...',
      callback: startCallback,
    );
  }

  Future<void> _cancelNotification() async {
    await FlutterForegroundTask.stopService();
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
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
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
                  backgroundColor: const Color(0xFF2D2938),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                ),
          backgroundColor: const Color(0xFF433E57),
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
                  color: const Color(0xFF2D2938),
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
                backgroundColor: const Color(0xFF583AC5),
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
    return Column(
      children: [
        // ⬛ 검정 박스: 타이머 시간 + 아이콘만 포함
        Container(
          width: 260, // 박스 전체 너비
          height: 148, // (선택) 높이 조정
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0x807E62E2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ⏱ 타이머 텍스트 박스
              Container(
                width: double.infinity, // 박스 전체 기준으로 맞춤
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF583AC5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(_remainingTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // ▶️⏸️⏹️ 아이콘 버튼들
              // ▶️⏸️⏹️ 아이콘 버튼들 (기능 연결됨)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _countdownTimer?.cancel(); // 일시정지
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/pause.png', width: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 0),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_remainingTime > Duration.zero) {
                          _startTimer(); // 재생
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/play.png', width: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 0),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _cancelTimer, // 정지
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/stop.png', width: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildTimerButtonsGrid(),
      ],
    );
  }

  Widget _buildTimerButtonsGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimerRow("1시간", const Duration(hours: 1)),
            const SizedBox(width: 12),
            _buildTimerRow("30분", const Duration(minutes: 30)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimerRow("10분", const Duration(minutes: 10)),
            const SizedBox(width: 12),
            _buildTimerRow("5분", const Duration(minutes: 5)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerRow(String label, Duration duration) {
    return Container(
      width: 120, // 버튼 하나 기준 70% 크기
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF583AC5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCircleIcon("+", () => _addTime(duration)),
          Expanded(
            child: Container(
              color: const Color(0xFF2D2938),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          _buildCircleIcon("–", () => _addTime(-duration)),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 30,
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
        color: const Color(0xFF7E62E2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF583AC5)),
      ),
      child: Text(
        _messages[_messageIndex],
        style: const TextStyle(
          color: Colors.white,
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
