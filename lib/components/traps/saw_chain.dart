import 'dart:async';

import 'package:flame/components.dart';

import '../../pixel_adventure.dart';

class SawChain extends SpriteComponent with HasGameRef<PixelAdventure> {
  SawChain({
    position,
    size
  }) : super(
    position: position,
    size: size
  );

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Traps/Saw/Chain.png'));
    return super.onLoad();
  }
}
