import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/difficulty.dart';

enum SessionPhase { title, playing, result }

/// アプリ全体の状態を保持するViewModel。
///
/// - Flutter Widget (Overlay) と Flame Component (Game) の両方から参照される
///   「唯一の状態源(single source of truth)」。
/// - サドンデス制: ミスするまで連続in数を数え続け、View側(UI・ゲーム描画)は
///   その連続記録とカップ速度を表示・反映するだけにする。
class GameViewModel extends ChangeNotifier {
  SessionPhase _phase = SessionPhase.title;
  int _sessionCount = 0;
  int _landedInCup = 0;

  /// 連続in回数(サドンデスではミスした瞬間にゲームが終わるため、
  /// 「連続成功数」は常にここまでの成功総数と一致する)。
  int get landedInCup => _landedInCup;

  SessionPhase get phase => _phase;

  Difficulty get currentDifficulty => Difficulty.forSession(_sessionCount);

  /// 連続in数に応じたカップ速度の倍率(1.0が等倍)。BGMの再生速度もこれに合わせる。
  double get cupSpeedMultiplier =>
      GameConfig.cupSpeedMultiplierForStreak(_landedInCup);

  /// 現在の紙コップ移動速度(px/s)。連続in数に応じた倍率を難易度基準速度に掛けて求める。
  double get cupSpeed => currentDifficulty.speed * cupSpeedMultiplier;

  /// サドンデス制: ミスするまでは何投でも投げられる。
  bool get canThrow => _phase == SessionPhase.playing;

  /// タイトル画面からゲーム開始。
  void startGame() {
    _landedInCup = 0;
    _phase = SessionPhase.playing;
    notifyListeners();
  }

  /// 1投分の結果を登録する。KaraageComponentの衝突判定確定時に呼ばれる。
  ///
  /// [success] カップに入ったか。inすれば連続記録を伸ばして続行、
  /// ミスすれば即座にゲームオーバー(サドンデス)。
  void registerThrow({required bool success}) {
    if (_phase != SessionPhase.playing) return;

    if (!success) {
      _finishSession();
      return;
    }

    _landedInCup += 1;
    notifyListeners();
  }

  void _finishSession() {
    _sessionCount += 1;
    _phase = SessionPhase.result;
    notifyListeners();
  }

  /// リザルト画面から「もう一度」。難易度は_sessionCountに応じて自動で上がる。
  void retry() {
    startGame();
  }

  /// タイトルへ戻る(難易度もリセットしたい場合に使用)。
  void backToTitle() {
    _phase = SessionPhase.title;
    _sessionCount = 0;
    notifyListeners();
  }
}
