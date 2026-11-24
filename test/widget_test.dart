import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awake/main.dart';
import 'package:awake/wakelock_service.dart';

class FakeWakelockService implements WakelockService {
  bool enabled = false;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enabled = true;
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    enabled = false;
    disableCalls++;
  }

  @override
  Future<bool> isEnabled() async => enabled;
}

void main() {
  testWidgets('enables wakelock automatically on launch and shows active UI', (
    WidgetTester tester,
  ) async {
    final service = FakeWakelockService();

    await tester.pumpWidget(WakelockApp(wakelockService: service));
    await tester.pump();

    expect(service.enabled, isTrue);
    expect(service.enableCalls, 1);
    expect(find.text('WAKELOCK ON'), findsOneWidget);
    expect(find.text('Screen Awake'), findsOneWidget);
  });

  testWidgets('tapping orb toggles wakelock off and back on', (
    WidgetTester tester,
  ) async {
    final service = FakeWakelockService();

    await tester.pumpWidget(WakelockApp(wakelockService: service));
    await tester.pump();

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(service.enabled, isFalse);
    expect(find.text('WAKELOCK OFF'), findsOneWidget);
    expect(find.text('Wakelock Paused'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(service.enabled, isTrue);
    expect(find.text('WAKELOCK ON'), findsOneWidget);
    expect(find.text('Screen Awake'), findsOneWidget);
  });

  testWidgets('keeps wakelock enabled when minimized and disables on detach', (
    WidgetTester tester,
  ) async {
    final service = FakeWakelockService();

    await tester.pumpWidget(WakelockApp(wakelockService: service));
    await tester.pump();
    expect(service.enabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(service.enabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();
    expect(service.enabled, isFalse);
  });

  testWidgets('disables wakelock when widget is disposed', (
    WidgetTester tester,
  ) async {
    final service = FakeWakelockService();

    await tester.pumpWidget(WakelockApp(wakelockService: service));
    await tester.pump();
    expect(service.enabled, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(service.enabled, isFalse);
  });
}
