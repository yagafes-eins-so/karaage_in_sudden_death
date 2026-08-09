import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color, ValueNotifier;

import '../core/audio_manager.dart';
import '../core/constants.dart';
import '../viewmodels/game_view_model.dart';
import 'components/aim_trajectory_component.dart';
import 'components/background_component.dart';
import 'components/confetti_component.dart';
import 'components/cup_component.dart';
import 'components/ground_component.dart';
import 'components/karaage_component.dart';
import 'components/player_component.dart';
import 'game_state.dart';
import 'physics/projectile_physics.dart';

/// ゲーム本体。
///
/// 設計方針:
/// - このクラスは「配線役」に徹する。連続in数(サドンデス)の管理はGameViewModelに、
///   物理計算はProjectilePhysicsに、見た目は各Componentに委譲する。
/// - GameViewModelの変更を購読し、overlays(Flutter Widget側)を切り替える。
class KaraageGame extends FlameGame with DragCallbacks, HasCollisionDetection {
  KaraageGame({required this.viewModel});

  final GameViewModel viewModel;

  late PlayerComponent player;
  late CupComponent cup;
  late GroundComponent ground;
  late AimTrajectoryComponent aimGuide;

  bool _isAiming = false;
  Vector2 _lastLocalPosition = Vector2.zero();
  Vector2? _touchStartPosition;

  bool _bgmStarted = false;

  /// BGMの現在の再生速度と、これから近づけていく目標速度。
  /// 段階的に変わる目標値に対して毎フレーム少しずつ追従させることで、
  /// カクッと切り替わらず自然に加減速しているように聞こえるようにする。
  double _bgmRate = 1.0;
  double _bgmTargetRate = 1.0;

  /// 目標速度への追従の速さ(大きいほど素早く目標に近づく)。調整用に変数化。
  static const double _bgmRateFollowSpeed = 2.5;

  /// "IN!!" / "MISS" ポップアップ表示用。FeedbackOverlay が購読する。
  final ValueNotifier<String?> feedbackText = ValueNotifier(null);

  static const double _throwAreaBottomRatio = 0.85;

  @override
  Color backgroundColor() => AppColors.yellow;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // AudioManager.preload自体は内部で例外を握りつぶすが、
    // 念のためここでも二重に防御しておく(何があってもゲーム初期化を止めない)。
    try {
      await AudioManager.instance.preload();
    } catch (_) {}

    add(BackgroundComponent(size: size));

    // 左側: プレイヤー(投球位置は固定)。
    final playerPos = Vector2(size.x * 0.28, size.y * 0.80);
    player = PlayerComponent(
      position: playerPos,
      size: Vector2.all(size.y * 0.56),
    );
    add(player);

    // 中央: 投球エリア下端の地面(ここに触れたら失敗)。
    ground = GroundComponent(
      position: Vector2(size.x * 0.22, size.y * _throwAreaBottomRatio),
      size: Vector2(size.x * 0.6, size.y * 0.06),
    );
    add(ground);

    // 右側: 紙コップ(左右往復)。
    final travelMinX = size.x * 0.66;
    final travelMaxX = size.x * 0.92;
    cup = CupComponent(
      travelMinX: travelMinX,
      travelMaxX: travelMaxX,
      initialSpeed: viewModel.currentDifficulty.speed,
      position: Vector2(travelMinX, size.y * 0.52),
      size: Vector2(size.x * 0.13, size.y * 0.22),
    );
    add(cup);

    aimGuide = AimTrajectoryComponent(origin: playerPos.clone());
    add(aimGuide);

    overlays.add(GameOverlays.title);
    viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    switch (viewModel.phase) {
      case SessionPhase.title:
        _showOnly(GameOverlays.title);
        AudioManager.instance.stopBgm();
        _bgmStarted = false;
        break;
      case SessionPhase.playing:
        overlays.clear();
        overlays.add(GameOverlays.hud);
        overlays.add(GameOverlays.feedback);
        cup.updateSpeed(viewModel.cupSpeed);
        _bgmTargetRate = viewModel.cupSpeedMultiplier;
        if (!_bgmStarted) {
          // 新しいセッションの開始時は、直前の余韻を残さず等倍から始める。
          _bgmRate = 1.0;
          AudioManager.instance.playBgm();
          _bgmStarted = true;
        }
        break;
      case SessionPhase.result:
        _showOnly(GameOverlays.result);
        AudioManager.instance.stopBgm();
        _bgmStarted = false;
        // ゲームオーバー時点でサドンデスによる速度上昇をリセットする
        // (リザルト画面の裏でカップが速いまま動き続けるのを防ぐ)。
        cup.updateSpeed(viewModel.currentDifficulty.speed);
        _bgmTargetRate = 1.0;
        // サドンデスでは何連続inできたかを「Perfect」相当の見せ場として扱う。
        // 閾値は旧来の5投固定制と同じ5連続を基準にしており、調整が必要ならここを変える。
        if (viewModel.landedInCup >= 5) {
          AudioManager.instance.playPerfect();
        }
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateBgmRate(dt);
  }

  /// BGMの再生速度を目標値へ毎フレーム少しずつ近づけ、自然な加減速に見せる。
  void _updateBgmRate(double dt) {
    final diff = _bgmTargetRate - _bgmRate;
    if (diff.abs() < 0.005) {
      if (_bgmRate != _bgmTargetRate) {
        _bgmRate = _bgmTargetRate;
        AudioManager.instance.setBgmSpeed(_bgmRate);
      }
      return;
    }
    _bgmRate += diff * (dt * _bgmRateFollowSpeed).clamp(0.0, 1.0);
    AudioManager.instance.setBgmSpeed(_bgmRate);
  }

  void _showOnly(String overlayName) {
    overlays.clear();
    overlays.add(overlayName);
  }

  // ---- ドラッグ操作(スリングショット式の狙い) ----
  //
  // プレイヤー付近からドラッグを開始し、離した瞬間の
  // 「プレイヤー位置→指を離した位置」のベクトルを ProjectilePhysics に渡す。
  // 引っ張った向きと逆方向に飛ぶ(パチンコ式)。

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!viewModel.canThrow) return;

    _touchStartPosition = event.localPosition.clone();
    _isAiming = true;
    _lastLocalPosition = event.localPosition.clone();
    player.setState(PlayerState.aiming);
    AudioManager.instance.playCharge();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isAiming || _touchStartPosition == null) return;

    _lastLocalPosition += event.localDelta;
    final dragVector = _lastLocalPosition - _touchStartPosition!;
    aimGuide.updateAim(dragVector);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isAiming || _touchStartPosition == null) return;
    _isAiming = false;
    aimGuide.hide();

    final dragVector = _lastLocalPosition - _touchStartPosition!;
    _throw(dragVector);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _resetAim();
  }

  void _resetAim() {
    _isAiming = false;
    aimGuide.hide();
    if (viewModel.canThrow) player.setState(PlayerState.idle);
  }

  void _throw(Vector2 dragVector) {
    if (!ProjectilePhysics.isValidThrow(dragVector)) {
      // 誤操作(ほぼドラッグしていない)は投球扱いにしない。
      if (viewModel.canThrow) player.setState(PlayerState.idle);
      return;
    }

    player.setState(PlayerState.throwing);
    AudioManager.instance.playThrow();

    final velocity = ProjectilePhysics.velocityFromDrag(dragVector);
    final karaage = KaraageComponent(
      startPosition: player.position.clone(),
      initialVelocity: velocity,
      worldSize: size,
      onResolved: _onThrowResolved,
    );
    add(karaage);
  }

  void _onThrowResolved({required bool success}) {
    player.setState(success ? PlayerState.happy : PlayerState.sad);
    if (success) {
      AudioManager.instance.playSuccess();
      ConfettiComponent.spawn(this, at: cup.position.clone());
      feedbackText.value = 'IN!!';
    } else {
      AudioManager.instance.playMiss();
      feedbackText.value = 'MISS';
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      feedbackText.value = null;

      // フィードバック表示が終わってから登録することで、
      // ミス時のリザルト表示がフィードバックの後に行われるようにする。
      viewModel.registerThrow(success: success);
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (viewModel.canThrow) player.setState(PlayerState.idle);
    });
  }

  @override
  void onRemove() {
    viewModel.removeListener(_onViewModelChanged);
    feedbackText.dispose();
    super.onRemove();
  }
}
