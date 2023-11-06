import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Saw extends SpriteAnimationComponent with HasGameRef<PixelAdventure> {
  final bool isVertical;
  final double offPos, offNeg;
  Saw({
    position,
    size,
    this.isVertical = false,
    this.offPos = 0.0,
    this.offNeg = 0.0,
  }) : super(position: position, size: size);

  static const sawSpeed = 0.03;
  static const moveSpeed = 50;
  static const tileSize = 16;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    // debugMode = true;
    add(CircleHitbox());

    if (isVertical) {
      rangeNeg = position.y - offNeg * tileSize;
      rangePos = position.y + offPos * tileSize;
    } else {
      rangeNeg = position.x - offNeg * tileSize;
      rangePos = position.x + offPos * tileSize;
    }

    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache("Traps/Saw/On (38x38).png"),
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: sawSpeed,
        textureSize: Vector2.all(38),
      ),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isVertical) {
      if (position.y >= rangePos) {
        moveDirection = -1;
      } else if (position.y <= rangeNeg) {
        moveDirection = 1;
      }
      position.y += moveDirection * moveSpeed * dt;
    } else {
      if (position.x >= rangePos) {
        moveDirection = -1;
      } else if (position.x <= rangeNeg) {
        moveDirection = 1;
      }
      position.x += moveDirection * moveSpeed * dt;
    }
    super.update(dt);
  }
}
