import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class JumpButton extends SpriteComponent
    with HasGameRef<PixelAdventure>, TapCallbacks {
  Function(bool) onTap;
  JumpButton({required this.onTap});

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));
    position = Vector2(
      game.size.x - joystickMargin - joystickSize,
      game.size.y - joystickMargin - joystickSize,
    );
    size = Vector2.all(joystickSize);
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap.call(true);
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap.call(false);
    super.onTapUp(event);
  }
}
