import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';

/// The "say it yourself" section used on the practice screens: mic button,
/// live transcript preview, and processing state.
///
/// One tap starts recording, the same tap again stops it AND immediately
/// checks the pronunciation - no separate "Check pronunciation" button to
/// hunt for. Recording and processing each get their own unmistakable
/// visual state: a pulsing ring while listening, and a clearly labelled
/// banner (not just a tiny spinner) while the recording is being checked,
/// so it never looks like the app has frozen.
class MicRecorderSection extends StatefulWidget {
  final bool isRecording;
  final bool isChecking;
  final String liveText;

  /// Called on every tap. When not recording, this should start recording.
  /// When recording, this should stop recording AND kick off the
  /// pronunciation check in one go.
  final VoidCallback onMicTap;
  final bool showHeading;

  const MicRecorderSection({
    super.key,
    required this.isRecording,
    required this.isChecking,
    required this.liveText,
    required this.onMicTap,
    this.showHeading = true,
  });

  @override
  State<MicRecorderSection> createState() => _MicRecorderSectionState();
}

class _MicRecorderSectionState extends State<MicRecorderSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _hintText {
    if (widget.isChecking) return 'Checking your pronunciation…';
    if (widget.isRecording) return 'Listening… tap again to check';
    return 'Tap and speak';
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Column(
      children: [
        if (widget.showHeading) ...[
          const Text(
            'Now say it yourself',
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: r.space(14)),
        ],
        SizedBox(
          width: r.micButtonRadius * 2.6,
          height: r.micButtonRadius * 2.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isRecording)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.5);
                    final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: r.micButtonRadius * 2,
                          height: r.micButtonRadius * 2,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (widget.isChecking)
                SizedBox(
                  width: r.micButtonRadius * 2.2,
                  height: r.micButtonRadius * 2.2,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.accentGold,
                  ),
                ),
              GestureDetector(
                onTap: widget.isChecking ? null : widget.onMicTap,
                child: CircleAvatar(
                  radius: r.micButtonRadius,
                  backgroundColor: widget.isChecking
                      ? AppColors.locked
                      : (widget.isRecording ? AppColors.danger : AppColors.primaryDark),
                  child: widget.isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Icon(
                          widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.space(10)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _hintText,
            key: ValueKey(_hintText),
            style: TextStyle(
              color: widget.isChecking ? AppColors.accentGold : AppColors.textMuted,
              fontWeight: widget.isChecking ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        if (widget.liveText.isNotEmpty) ...[
          SizedBox(height: r.space(12)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              widget.liveText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: r.font(18)),
            ),
          ),
        ],
      ],
    );
  }
}
