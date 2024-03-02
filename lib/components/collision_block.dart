import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isBound;
  CollisionBlock({
    position,
    size,
    this.isPlatform = false,
    this.isBound = false
  }) : super(
    position: position,
    size: size
  );
}
