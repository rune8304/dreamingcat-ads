import 'dart:async';
import 'dart:isolate'; // ✅ 필수!
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground Task에서 실행될 핸들러 클래스
class MyForegroundTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("🌙 Foreground Task 시작됨");
    // 필요한 초기화 코드 가능
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    print("📡 Foreground Task 주기 이벤트 발생 (백그라운드 유지용)");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print("💤 Foreground Task 종료됨");
    _timer?.cancel();
  }

  @override
  void onNotificationPressed() {
    print("📱 알림 클릭됨 → 앱으로 전환 시도");
    FlutterForegroundTask.launchApp();
  }

  @override
  void onButtonPressed(String id) {
    print("🔘 알림 버튼 클릭됨: $id");
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // 반복 이벤트 처리 필요 시 여기에 작성
    // print("🔁 반복 이벤트 발생: $timestamp");
  }
}

/// Foreground Task 시작 시 실행되는 콜백 함수 (필수)
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}
