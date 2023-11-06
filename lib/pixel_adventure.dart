import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/level_data.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xFF211F30);

  late CameraComponent cam;
  late Player player;
  late JoystickComponent joystick;
  bool showJoystick = false;
  int currentLevel = 0;

  List<LevelData> levelData = [
    LevelData(levelName: "Level-02", playerName: "Pink Man"),
    LevelData(levelName: "Level-02", playerName: "Mask Dude")
  ];

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    _loadLevel();

    if (showJoystick) {
      addJoystick();
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache(
            "HUD/Joystick.png",
          ),
        ),
      ),
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache(
            "HUD/Knob.png",
          ),
        ),
      ),
      margin: const EdgeInsets.only(
        left: 32,
        bottom: 32,
      ),
    );
    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
    }
  }

  void loadNextLevel() {
    currentLevel = (currentLevel + 1) % levelData.length;
    _loadLevel();
  }

  void _loadLevel() {
    const levelChangeDuration = Duration(seconds: 1);
    player = Player(character: levelData[currentLevel].playerName);
    Future.delayed(levelChangeDuration, () {
      final world = Level(
        levelName: levelData[currentLevel].levelName,
        player: player,
      );

      cam = CameraComponent.withFixedResolution(
        width: 640,
        height: 360,
        world: world,
      );
      cam.viewfinder.anchor = Anchor.topLeft;
      addAll([
        cam,
        world,
      ]);
    });
  }
}
