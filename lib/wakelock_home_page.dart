import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'wakelock_service.dart';

class WakelockHomePage extends StatefulWidget {
  const WakelockHomePage({
    super.key,
    this.wakelockService = const WakelockPlusService(),
  });

  final WakelockService wakelockService;

  @override
  State<WakelockHomePage> createState() => _WakelockHomePageState();
}

class _WakelockHomePageState extends State<WakelockHomePage>
    with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycleListener;
  late final AnimationController _pulseController;
  Timer? _durationTimer;

  bool _isWakelockActive = false;
  bool _isBusy = false;
  String? _errorMessage;
  Duration _activeDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _lifecycleListener = AppLifecycleListener(
      onDetach: _handleDetach,
      onExitRequested: _handleExitRequested,
    );

    unawaited(_enableWakelock());
  }

  Future<void> _enableWakelock() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.wakelockService.enable();
      if (!mounted) return;
      _startSessionTracking();
      setState(() {
        _isWakelockActive = true;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) return;
      _stopSessionTracking();
      setState(() {
        _isWakelockActive = false;
        _isBusy = false;
        _errorMessage = 'Unable to activate wakelock on this device.';
      });
    }
  }

  Future<void> _disableWakelock({bool resetDuration = false}) async {
    try {
      await widget.wakelockService.disable();
    } catch (_) {
      // Ignore disable errors during teardown/backgrounding.
    }

    _stopSessionTracking(resetDuration: resetDuration);
    if (!mounted) return;
    setState(() {
      _isWakelockActive = false;
      _isBusy = false;
    });
  }

  void _startSessionTracking() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isWakelockActive) return;
      setState(() {
        _activeDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopSessionTracking({bool resetDuration = false}) {
    _pulseController.stop();
    _pulseController.reset();
    _durationTimer?.cancel();
    _durationTimer = null;
    if (resetDuration) {
      _activeDuration = Duration.zero;
    }
  }

  void _handleDetach() {
    if (_isWakelockActive) {
      unawaited(_disableWakelock(resetDuration: true));
    }
  }

  Future<AppExitResponse> _handleExitRequested() async {
    await _disableWakelock(resetDuration: true);
    return AppExitResponse.exit;
  }

  Future<void> _toggleWakelock() async {
    if (_isBusy) return;
    if (_isWakelockActive) {
      await _disableWakelock(resetDuration: true);
    } else {
      await _enableWakelock();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _durationTimer?.cancel();
    _pulseController.dispose();
    unawaited(widget.wakelockService.disable());
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isWakelockActive;
    final accentColor = isActive
        ? const Color(0xFF34D399)
        : const Color(0xFF64748B);
    final secondaryGlow = isActive
        ? const Color(0xFF059669)
        : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.18),
            radius: 1.05,
            colors: [
              secondaryGlow.withValues(alpha: isActive ? 0.22 : 0.10),
              const Color(0xFF0B1120),
              const Color(0xFF070B14),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusBadge(
                            isActive: isActive,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 24),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WakelockOrb(
                                isActive: isActive,
                                isBusy: _isBusy,
                                accentColor: accentColor,
                                pulseAnimation: _pulseController,
                                onTap: _toggleWakelock,
                              ),
                              const SizedBox(height: 28),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: Text(
                                  isActive ? 'Screen Awake' : 'Wakelock Paused',
                                  key: ValueKey(isActive),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isActive
                                    ? 'Your Windows display will stay awake while this app is open. Close the window to stop.'
                                    : 'Normal Windows sleep settings apply. Click the button above to keep your screen awake.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  _errorMessage!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFF87171),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 24),
                              _SessionTimerChip(
                                isActive: isActive,
                                formattedDuration: _formatDuration(
                                  _activeDuration,
                                ),
                                accentColor: accentColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _FooterInfoCard(isActive: isActive),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isActive,
    required this.accentColor,
  });

  final bool isActive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'WAKELOCK ON' : 'WAKELOCK OFF',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WakelockOrb extends StatelessWidget {
  const _WakelockOrb({
    required this.isActive,
    required this.isBusy,
    required this.accentColor,
    required this.pulseAnimation,
    required this.onTap,
  });

  final bool isActive;
  final bool isBusy;
  final Color accentColor;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isActive,
      label: isActive ? 'Turn off wakelock' : 'Turn on wakelock',
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, _) {
                  final progress = pulseAnimation.value;
                  final scale = 0.72 + (progress * 0.45);
                  final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.35;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: opacity),
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (isActive)
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, _) {
                  final shifted = (pulseAnimation.value + 0.5) % 1.0;
                  final scale = 0.72 + (shifted * 0.45);
                  final opacity = (1.0 - shifted).clamp(0.0, 1.0) * 0.25;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isBusy ? null : onTap,
                customBorder: const CircleBorder(),
                splashColor: accentColor.withValues(alpha: 0.2),
                highlightColor: accentColor.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? const [Color(0xFF10B981), Color(0xFF047857)]
                          : const [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6EE7B7).withValues(alpha: 0.65)
                          : const Color(0xFF334155),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: isActive ? 0.42 : 0.12,
                        ),
                        blurRadius: isActive ? 42 : 18,
                        spreadRadius: isActive ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        isActive
                            ? Icons.light_mode_rounded
                            : Icons.bedtime_rounded,
                        key: ValueKey(isActive),
                        size: 56,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTimerChip extends StatelessWidget {
  const _SessionTimerChip({
    required this.isActive,
    required this.formattedDuration,
    required this.accentColor,
  });

  final bool isActive;
  final String formattedDuration;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isActive ? accentColor : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Awake for $formattedDuration' : 'Paused',
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterInfoCard extends StatelessWidget {
  const _FooterInfoCard({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.exit_to_app_rounded,
            size: 20,
            color: isActive
                ? const Color(0xFF34D399)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Stays active while open — stops automatically when you exit',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
