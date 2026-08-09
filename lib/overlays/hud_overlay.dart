import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../viewmodels/game_view_model.dart';

/// プレイ中に常時表示するHUD。サドンデスの連続in記録を右上に表示する。
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.viewModel});

  final GameViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Badge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, size: 22, color: AppColors.charcoal),
                      const SizedBox(width: 6),
                      Text(
                        '${viewModel.landedInCup}連続',
                        style: const TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.charcoal, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.charcoal, offset: Offset(3, 3)),
        ],
      ),
      child: child,
    );
  }
}
