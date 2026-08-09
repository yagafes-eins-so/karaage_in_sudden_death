import 'package:flutter/material.dart';

import '../core/audio_manager.dart';
import '../core/constants.dart';
import '../game/karaage_game.dart';
import '../viewmodels/game_view_model.dart';
import '../widgets/pop_button.dart';

/// タイトル画面。ゲームタイトル・簡単な説明・スタートボタンのみのシンプル構成。
class TitleOverlay extends StatelessWidget {
  const TitleOverlay({super.key, required this.game, required this.viewModel});

  final KaraageGame game;
  final GameViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 480;
    final titleFontSize = compact ? 24.0 : 30.0;
    final descriptionFontSize = compact ? 13.0 : 14.0;
    final titlePadding = compact
        ? const EdgeInsets.symmetric(horizontal: 22, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 28, vertical: 10);
    final verticalGap = compact ? 10.0 : 12.0;
    final buttonGap = compact ? 18.0 : 28.0;

    return Container(
      color: AppColors.charcoal.withValues(alpha: 0.55),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: titlePadding,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.charcoal, width: 4),
                        boxShadow: const [
                          BoxShadow(color: AppColors.charcoal, offset: Offset(6, 6)),
                        ],
                      ),
                      child: Text(
                        'からあげin!　サドンデス',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalGap),
                    Text(
                      'ヤガあげクンを操作して、紙コップに唐揚げを投げ入れよう!\n'
                      'ドラッグして狙いを定め、指を離すと発射!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: descriptionFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: buttonGap),
                    PopButton(
                      label: 'スタート',
                      color: AppColors.red,
                      textColor: AppColors.cream,
                      onPressed: () {
                        AudioManager.instance.playClick();
                        viewModel.startGame();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
