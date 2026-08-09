/// 難易度ごとのカップ移動パラメータ。
/// プレイ回数(セッション数)に応じて `Difficulty.forSession` が段階を上げる。
enum Difficulty {
  easy(speed: 90, rangeRatio: 0.25, label: 'Easy'),
  normal(speed: 165, rangeRatio: 0.35, label: 'Normal'),
  hard(speed: 255, rangeRatio: 0.45, label: 'Hard');

  const Difficulty({
    required this.speed,
    required this.rangeRatio,
    required this.label,
  });

  /// カップの左右移動速度(px/s)。
  final double speed;

  /// 画面右エリア幅に対する移動範囲の割合。
  final double rangeRatio;

  final String label;

  /// これまでのプレイ回数(0始まり)から難易度を決定する。
  /// 例: 0,1回目=Easy / 2,3回目=Normal / 4回目以降=Hard
  static Difficulty forSession(int sessionCount) {
    if (sessionCount <= 1) return Difficulty.easy;
    if (sessionCount <= 3) return Difficulty.normal;
    return Difficulty.hard;
  }
}
