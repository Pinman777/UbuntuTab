import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:ubuntutab/theme/droid_theme.dart';
import 'package:ubuntutab/state/app_state.dart';
import 'package:ubuntutab/screens/home_screen.dart';

/// Setup progress screen — step 3 of setup wizard.
/// Shows download, extraction, and configuration progress.
class SetupProgressScreen extends StatefulWidget {
  const SetupProgressScreen({super.key});

  @override
  State<SetupProgressScreen> createState() => _SetupProgressScreenState();
}

class _SetupProgressScreenState extends State<SetupProgressScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSetup();
    });
  }

  Future<void> _startSetup() async {
    if (_started) return;
    _started = true;
    final state = context.read<AppState>();

    final freeStorage = (state.deviceInfo['availableStorageMB'] as num?)
        ?.toInt();
    if (freeStorage != null && freeStorage < 2048) {
      final continueAnyway =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(
                Icons.storage_rounded,
                color: DroidTheme.warning,
                size: 38,
              ),
              title: const Text('Low storage'),
              content: Text(
                'Only $freeStorage MB is available. Desktop Essentials works best with at least 2 GB free. You can continue, but package installation may fail.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Go back'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Continue anyway'),
                ),
              ],
            ),
          ) ??
          false;
      if (!continueAnyway) {
        _started = false;
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
    }

    if (!mounted) return;
    state.runSetup();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Determine overall phase
    final phase = _getPhase(state);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: DroidTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => state.toggleThemeMode(),
                    tooltip: state.isDarkMode
                        ? 'Switch to Light Theme'
                        : 'Switch to Dark Theme',
                    icon: Icon(
                      state.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: DroidTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(flex: 1),

                // ── Circular Progress ──
                CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 6,
                      percent: phase.progress.clamp(0.0, 1.0),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            phase.icon,
                            size: 36,
                            color: phase.error
                                ? DroidTheme.error
                                : DroidTheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(phase.progress * 100).toInt()}%',
                            style: DroidTheme.headingSm.copyWith(
                              color: phase.error
                                  ? DroidTheme.error
                                  : DroidTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      progressColor: phase.error
                          ? DroidTheme.error
                          : DroidTheme.primary,
                      backgroundColor: DroidTheme.surfaceBorder,
                      circularStrokeCap: CircularStrokeCap.round,
                      animateFromLastPercent: true,
                      animation: true,
                      animationDuration: 500,
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 32),

                // ── Phase Title ──
                Text(
                  phase.title,
                  style: DroidTheme.headingLg,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // ── Status Message ──
                Text(
                  phase.message,
                  style: DroidTheme.bodyMd.copyWith(
                    color: phase.error
                        ? DroidTheme.error
                        : DroidTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 48),

                // ── Steps Checklist ──
                _buildChecklist(state),

                if (state.setupLog.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildInstallLog(state.setupLog),
                ],

                const Spacer(flex: 1),

                // ── Action Buttons ──
                if (phase.error) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        state.clearError();
                        _started = false;
                        _startSetup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DroidTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                ] else if (phase.complete) ...[
                  SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DroidTheme.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Launch UbuntuTab'),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),
                ],

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(AppState state) {
    final done = state.isSetupComplete ? 6 : state.setupStage;
    final labels = [
      'Bootstrap environment',
      'Download Ubuntu 24.04 image',
      'Install apt packages',
      'Set up XFCE desktop',
      'Install QwenPaw',
      'Finalize',
    ];
    return _checklistColumn([
      for (var i = 0; i < labels.length; i++)
        _ChecklistItem(
          label: labels[i],
          done: done >= i + 1,
          active: done == i && !state.isSetupComplete,
        ),
    ]);
  }

  Widget _buildInstallLog(String log) {
    final cleanLog = log.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF080D18),
        border: Border.all(color: const Color(0xFF2C2C2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          cleanLog,
          // The log panel stays dark in both themes, so its text is always light.
          style: DroidTheme.monoSm.copyWith(
            color: const Color(0xFFE5E5EA),
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _checklistColumn(List<_ChecklistItem> steps) {
    return Column(
      children: steps
          .asMap()
          .entries
          .map((entry) {
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Status icon
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: item.done
                        ? Icon(
                            Icons.check_circle,
                            color: DroidTheme.accent,
                            size: 20,
                          )
                        : item.active
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DroidTheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.circle_outlined,
                            color: DroidTheme.textDim,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: DroidTheme.bodyMd.copyWith(
                        color: item.done
                            ? DroidTheme.textPrimary
                            : item.active
                            ? DroidTheme.textSecondary
                            : DroidTheme.textDim,
                      ),
                    ),
                  ),
                  if (item.progress != null)
                    Text(
                      '${(item.progress! * 100).toInt()}%',
                      style: DroidTheme.monoSm.copyWith(
                        color: DroidTheme.primary,
                      ),
                    ),
                ],
              ),
            );
          })
          .toList()
          .animate(interval: 100.ms)
          .fadeIn(delay: 400.ms, duration: 300.ms)
          .slideX(begin: -0.05, duration: 300.ms),
    );
  }

  _PhaseInfo _getPhase(AppState state) {
    if (state.errorMessage != null) {
      return _PhaseInfo(
        title: 'Setup Failed',
        message: state.errorMessage!,
        progress: 0,
        icon: Icons.error_outline_rounded,
        error: true,
        complete: false,
      );
    }

    if (state.isDownloading) {
      return _PhaseInfo(
        title: 'Downloading',
        message: state.downloadStatus.isNotEmpty
            ? state.downloadStatus
            : 'Preparing download...',
        progress: state.downloadProgress * 0.5, // 0–50% of total
        icon: Icons.cloud_download_rounded,
        error: false,
        complete: false,
      );
    }

    if (state.isExtracting || state.isInstallingDE) {
      return _PhaseInfo(
        title: 'Installing Ubuntu',
        message: state.extractStatus.isNotEmpty
            ? state.extractStatus
            : 'Running ubuntu-setup.sh...',
        progress: (state.setupStage + 1) / 7,
        icon: Icons.terminal_rounded,
        error: false,
        complete: false,
      );
    }

    if (state.isSetupComplete) {
      return _PhaseInfo(
        title: 'Setup Complete!',
        message: 'Your Linux desktop is ready to launch.',
        progress: 1.0,
        icon: Icons.check_circle_rounded,
        error: false,
        complete: true,
      );
    }

    // Default: not started yet
    return _PhaseInfo(
      title: 'Setting Up',
      message: 'Initializing...',
      progress: 0,
      icon: Icons.settings_rounded,
      error: false,
      complete: false,
    );
  }
}

class _PhaseInfo {
  final String title;
  final String message;
  final double progress;
  final IconData icon;
  final bool error;
  final bool complete;

  _PhaseInfo({
    required this.title,
    required this.message,
    required this.progress,
    required this.icon,
    required this.error,
    required this.complete,
  });
}

class _ChecklistItem {
  final String label;
  final bool done;
  final bool active;
  final double? progress;

  _ChecklistItem({
    required this.label,
    required this.done,
    required this.active,
    this.progress,
  });
}
