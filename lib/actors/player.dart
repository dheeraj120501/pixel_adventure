import 'dart:async';

import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  hit,
  falling,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure> {
  String character;

  Player({required this.character, position}) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  final double stepTime = 0.05;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();

    return super.onLoad();
  }

  void _loadAllAnimations() {
    idleAnimation = _getAnimation("Idle", 11);
    runningAnimation = _getAnimation("Run", 12);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _getAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache("Main Characters/$character/$state (32x32).png"),
        SpriteAnimationData.sequenced(
            amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }
}
