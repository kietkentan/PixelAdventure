import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class BackgroundTile extends ParallaxComponent {
  final String color;

  BackgroundTile({
    this.color = 'Gray',
    size,
    position,
  }) : super(
    position: position,
    size: size,
    priority: -10
  );

  final double scrollSpeed = 40;

  @override
  FutureOr<void> onLoad() async {
    parallax = await gameRef.loadParallax(
        [ParallaxImageData('Background/$color.png')],
        baseVelocity: Vector2(0, -scrollSpeed),
        repeat: ImageRepeat.repeat,
        fill: LayerFill.none,
        filterQuality: FilterQuality.none
    );

    return super.onLoad();
  }
}
