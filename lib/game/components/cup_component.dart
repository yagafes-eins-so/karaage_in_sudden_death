import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// 紙コップ。左右に往復移動し、当たり判定を提供する。
///
/// 判定の考え方:
/// - `opening`(コップの飲み口=内側)に入れば成功
/// - `rim`(内側より少し広い外枠)にだけ当たった場合は失敗(コップ外側に当たる)
class CupComponent extends PositionComponent with CollisionCallbacks {
  CupComponent({
    required this.travelMinX,
    required this.travelMaxX,
    required double initialSpeed,
    required Vector2 position,
    required Vector2 size,
  })  : _speed = initialSpeed,
        super(position: position, size: size, anchor: Anchor.topCenter);

  final double travelMinX;
  final double travelMaxX;

  /// 現在の移動速度(px/s)。サドンデスでinするたびに外部(GameViewModel)から
  /// [updateSpeed] で更新される(難易度基準値からの倍率計算はViewModel側で行う)。
  double _speed;

  double _direction = 1;
  Sprite? _sprite;

  /// コップ内側(成功判定)の当たり判定。カップ幅の80%を「開口部」として扱う。
  late final RectangleHitbox openingHitbox;

  /// サドンデスでのin成功に応じて増加していく移動速度を反映する。
  void updateSpeed(double speed) => _speed = speed;

  @override
  Future<void> onLoad() async {
    try {
      _sprite = await Sprite.load('cup.png');
    } catch (_) {
      _sprite = null;
    }

    // コップ本体の外側にもヒットボックスを持たせる。
    // これにより、赤い開口部以外に唐揚げが触れた場合にMISSと判定できる。
    add(RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      collisionType: CollisionType.passive,
    ));

    openingHitbox = RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.5),
      position: Vector2(size.x * 0.1, 0),
      collisionType: CollisionType.passive,
    )..isSolid = true;
    add(openingHitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    x += _direction * _speed * dt;
    if (x >= travelMaxX) {
      x = travelMaxX;
      _direction = -1;
    } else if (x <= travelMinX) {
      x = travelMinX;
      _direction = 1;
    }
  }

  /// 唐揚げの中心座標と半径から、赤い開口部領域へ完全に入っているか判定する。
  bool isFullyInOpening(Vector2 worldCenter, double radius) {
    // CupComponent は topCenter アンカーなので、左上のワールド座標は
    // absolutePosition.x - size.x / 2 となる。
    final cupTopLeft = Vector2(absolutePosition.x - size.x / 2, absolutePosition.y);
    final openingWorldX = cupTopLeft.x + openingHitbox.position.x;
    final openingWorldY = cupTopLeft.y + openingHitbox.position.y;
    final openingWidth = openingHitbox.size.x;
    final openingHeight = openingHitbox.size.y;

    final openingRect = Rect.fromLTWH(
      openingWorldX,
      openingWorldY,
      openingWidth,
      openingHeight,
    );

    // 円と矩形が重なっていれば成功とする。
    final closestX = worldCenter.x.clamp(openingRect.left, openingRect.right);
    final closestY = worldCenter.y.clamp(openingRect.top, openingRect.bottom);
    final dx = worldCenter.x - closestX;
    final dy = worldCenter.y - closestY;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
      return;
    }
    // フォールバック描画: 台形のコップ + 開口部の楕円。
    final bodyPaint = Paint()..color = AppColors.cream;
    final borderPaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.x * 0.12, 0)
      ..lineTo(size.x * 0.88, 0)
      ..lineTo(size.x * 0.72, size.y)
      ..lineTo(size.x * 0.28, size.y)
      ..close();
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, borderPaint);

    final openingPaint = Paint()..color = AppColors.red.withOpacity(0.85);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.12, -6, size.x * 0.76, 14),
      openingPaint,
    );
  }

  /// 成功した唐揚げの表示は廃止しています。
  /// 将来的に再表示したい場合はここにロジックを追加してください。
  void addLandedKaraage() {}

  /// リトライ時などに蓄積表示をリセットする。
  void resetLandedKaraage() {}
}

