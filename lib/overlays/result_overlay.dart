import 'package:flutter/material.dart';

import '../core/audio_manager.dart';
import '../core/constants.dart';
import '../viewmodels/game_view_model.dart';
import '../widgets/pop_button.dart';

/// リザルト画面。サドンデスの連続in記録だけを大きく表示し、リトライへ導線。
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({super.key, required this.viewModel});

  final GameViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final streakCount = viewModel.landedInCup;
    final screenSize = MediaQuery.of(context).size;
    final compact = screenSize.height < 480;
    final cardWidth = (screenSize.width * 0.85).clamp(220.0, 340.0);
    final cardPadding = compact ? const EdgeInsets.all(18) : const EdgeInsets.all(24);
    final titleFontSize = compact ? 20.0 : 22.0;
    final streakFontSize = compact ? 56.0 : 72.0;

    return Container(
      color: AppColors.charcoal.withValues(alpha: 0.6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  width: cardWidth,
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.charcoal, width: 4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.charcoal, offset: Offset(6, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RESULT',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: titleFontSize,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 24),
                      Text(
                        '$streakCount',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w900,
                          fontSize: streakFontSize,
                        ),
                      ),
                      const Text(
                        '連続成功',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 28),
                      PopButton(
                        label: 'もう一度',
                        color: AppColors.red,
                        textColor: AppColors.cream,
                        onPressed: () {
                          AudioManager.instance.playClick();
                          viewModel.retry();
                        },
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      TextButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          viewModel.backToTitle();
                        },
                        child: const Text(
                          'タイトルへ戻る',
                          style: TextStyle(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
