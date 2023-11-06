import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState { idle, running, jumping, hit, falling, spawn, death, success }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  String character;

  Player({
    this.character = "Ninja Frog",
    position,
  }) : super(position: position);

  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation disapearingAnimation;
  late final SpriteAnimation spawnAnimation;

  Vector2 spawnPosition = Vector2.all(0);
  late Vector2 deathPosition;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0.0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();

  bool firstSpawn = true;
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;

  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  @override
  FutureOr<void> onLoad() {
    spawnPosition = Vector2(position.x, position.y);
    _loadAllAnimations();
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    current = spawnAnimation;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotHit && !reachedCheckpoint) {
      if (firstSpawn) {
        position = spawnPosition - Vector2.all(32);
        current = PlayerState.spawn;
        Future.delayed(const Duration(milliseconds: 50 * 7), () {
          position = spawnPosition;
          _updatePlayerState();
          _updatePlayerMovement(dt);
          _checkHorizontalCollisions();
          _applyGravity(dt);
          _checkVerticalCollisions();
          firstSpawn = false;
        });
      } else {
        _updatePlayerState();
        _updatePlayerMovement(dt);
        _checkHorizontalCollisions();
        _applyGravity(dt);
        _checkVerticalCollisions();
      }
    }
    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0.0;

    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);

    return super.onKeyEvent(
      event,
      keysPressed,
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) {
        other.collidedWithPlayer();
      }
      if (other is Saw && !gotHit) {
        _respawn();
      }
      if (other is Checkpoint) {
        _reachedCheckpoint();
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _getAnimation("Idle", 11);
    runningAnimation = _getAnimation("Run", 12);
    jumpingAnimation = _getAnimation("Jump", 1);
    fallingAnimation = _getAnimation("Fall", 1);
    hitAnimation = _getAnimation("Hit", 7);
    disapearingAnimation = _getSpecialAnimation("Disappearing", 7);
    spawnAnimation = _getSpecialAnimation("Appearing", 7);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.spawn: spawnAnimation,
      PlayerState.death: disapearingAnimation,
      PlayerState.success: disapearingAnimation,
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _getAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(
        "Main Characters/$character/$state (32x32).png",
      ),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _getSpecialAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(
        "Main Characters/$state (96x96).png",
      ),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
      ),
    );
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) {
      _playerJump(dt);
    }

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x != 0) playerState = PlayerState.running;

    if (velocity.y > 0) playerState = PlayerState.falling;

    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _respawn() {
    const hitDuration = Duration(milliseconds: 50 * 7);
    const respawnDuration = Duration(milliseconds: 50 * 7);
    const activeDuration = Duration(milliseconds: 300);
    gotHit = true;
    deathPosition = position;
    current = PlayerState.hit;
    Future.delayed(
      hitDuration,
      () {
        if (scale.x > 0) {
          position -= Vector2.all(32);
        } else if (scale.x < 0) {
          position += Vector2(32, -32);
        }
        current = PlayerState.death;
        Future.delayed(
          hitDuration,
          () {
            scale.x = 1;
            position = spawnPosition - Vector2.all(32);
            current = PlayerState.spawn;
            Future.delayed(
              respawnDuration,
              () {
                velocity = Vector2(0, 0);
                position = spawnPosition;
                _updatePlayerState();
                Future.delayed(
                  activeDuration,
                  () {
                    gotHit = false;
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _reachedCheckpoint() {
    reachedCheckpoint = true;
    if (scale.x > 0) {
      position -= Vector2.all(32);
    } else if (scale.x < 0) {
      position += Vector2(32, -32);
    }
    current = PlayerState.success;

    const reachedCheckpointDuration = Duration(milliseconds: 50 * 7);

    Future.delayed(reachedCheckpointDuration, () {
      reachedCheckpoint = false;
      position = Vector2.all(-640);
      game.loadNextLevel();
    });
  }
}
