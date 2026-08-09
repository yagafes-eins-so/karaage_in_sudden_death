import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../physics/projectile_physics.dart';
import 'cup_component.dart';
import 'ground_component.dart';

/// 投球結果を親(KaraageGame)へ伝えるコールバック。
typedef OnThrowResolved = void Function({required bool success});

/// 唐揚げ本体。物理演算で自律的に飛び、地面/カップとの衝突で結果を確定する。
class KaraageComponent extends PositionComponent
    with CollisionCallbacks {
  KaraageComponent({
    required Vector2 startPosition,
    required this.initialVelocity,
    required this.worldSize,
    required this.onResolved,
  }) : super(
          position: startPosition,
          size: Vector2.all(worldSize.y * 0.12),
          anchor: Anchor.center,
        );

  Vector2 velocity = Vector2.zero();
  final Vector2 initialVelocity;
  final Vector2 worldSize;
  final OnThrowResolved onResolved;

  bool _resolved = false;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    velocity = initialVelocity.clone();
    try {
      _sprite = await Sprite.load('karaage.png');
    } catch (_) {
      _sprite = null;
    }
    add(CircleHitbox(radius: size.x / 2, collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_resolved) return;

    final nextPosition = ProjectilePhysics.integratePosition(
      position: position,
      velocity: velocity,
      dt: dt,
    );
    position
      ..x = nextPosition.x
      ..y = nextPosition.y;
    velocity = ProjectilePhysics.integrateVelocity(velocity: velocity, dt: dt);

    // 回転で「飛んでる感」を出す。
    angle += dt * 8;

    // 画面外に出たら失敗確定。
    if (position.x > worldSize.x + 40 ||
        position.x < -40 ||
        position.y > worldSize.y + 40) {
      _resolve(success: false);
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_resolved) return;

    if (other is GroundComponent) {
      // 地面にはまだ「着地」なだけで、直後にコップ判定がなければ失敗確定にする。
      Future.microtask(() {
        if (!_resolved) {
          _resolve(success: false);
        }
      });
      return;
    }

    if (other is CupComponent) {
      final fullyInOpening = other.isFullyInOpening(absolutePosition, size.x / 2);
      _resolve(success: fullyInOpening);
    }
  }

  void _resolve({required bool success}) {
    if (_resolved) return;
    _resolved = true;
    onResolved(success: success);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
      return;
    }
    // フォールバック: 唐揚げ風の丸みを帯びた不定形。
    final paint = Paint()..color = const Color(0xFFC97A2B);
    canvas.drawOval(size.toRect().deflate(1), paint);
    canvas.drawOval(
      size.toRect().deflate(1),
      Paint()
        ..color = AppColors.charcoal.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
