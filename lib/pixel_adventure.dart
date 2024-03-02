import 'dart:async';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/cupertino.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

import 'components/utils.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);

  PixelAdventure({required double scale}) {
    fixedResolution = Vector2(480, 480 * scale);
  }

  late CameraComponent cam;
  Player player = Player(character: 'Mask Dude');
  late JoystickComponent joystick;
  late JumpButton jumpButton;
  late Vector2 fixedResolution;
  bool showControls = true;
  bool playSounds = false;
  bool onDownPress = false;
  double soundVolume = 1.0;
  List<String> levelNames = ['Level-01', 'Level-02', 'Level-03', 'Level-04'];
  int currentLevelIndex = 0;

  Level? _currentLevel;

  @override
  FutureOr<void> onLoad() async {
    // Load all images into cache
    await images.loadAllImages();
    cam = CameraComponent.withFixedResolution(
      world: _currentLevel,
      width: fixedResolution.x,
      height: fixedResolution.y,
    );
    add(cam);

    _loadLevel();
    checkJoystick();

    if (showControls) {
      addJoystick();
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  void checkJoystick() {
    try {
      showControls = Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      showControls = false;
    }
  }

  void addJoystick() async {
    final bg = await images
        .fromCache('HUD/Joystick.png')
        .resize(Vector2.all(joystickSize));
    final kb = await images
        .fromCache('HUD/Knob.png')
        .resize(Vector2.all(joystickSize / 2));

    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(sprite: Sprite(kb)),
      background: SpriteComponent(sprite: Sprite(bg)),
      margin:
          const EdgeInsets.only(left: joystickMargin, bottom: joystickMargin),
    );
    jumpButton = JumpButton(onTap: (val) {
      onDownPress = val;
    });

    add(joystick);
    add(jumpButton);
  }

  void updateJoystick() {
    List<MyKeyEvent> listKey = [];
    if (onDownPress) {
      listKey.add(MyKeyEvent.keyUp);
      onDownPress = false;
    }
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        listKey.add(MyKeyEvent.keyLeft);
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        listKey.add(MyKeyEvent.keyRight);
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
    if (listKey.isNotEmpty) {
      player.updateKey(listKey);
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);

    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() {
    _currentLevel?.removeFromParent();
    Future.delayed(const Duration(seconds: 1), () {
      _currentLevel = Level(
        player: player,
        levelName: levelNames[currentLevelIndex],
      );

      add(_currentLevel!);
    });
  }
}
