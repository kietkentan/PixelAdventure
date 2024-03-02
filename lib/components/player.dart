import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/enemies/chicken.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/items/fruit.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/utils/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  doubleJump,
  falling,
  hit,
  wallJump,
  appearing,
  disappearing
}

enum MyKeyEvent {
  keyUp,
  keyLeft,
  keyRight
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  String character;
  Player({
    position,
    this.character = 'Ninja Frog',
  }) : super(position: position);

  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation doubleJumpAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation wallJumpAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  final double _gravity = 9.8;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300;
  final int _timeNotMove = 400;
  double horizontalMovement = 0;
  double horizontalClimbing = 0;
  double moveSpeed = 100;
  Vector2 desClimbing = Vector2.zero();
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool doubleJumped = false;
  bool hasDoubleJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  bool isClimbing = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }

      accumulatedTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    List<MyKeyEvent> listKey = [];
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      listKey.add(MyKeyEvent.keyLeft);
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      listKey.add(MyKeyEvent.keyRight);
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      listKey.add(MyKeyEvent.keyUp);
    }

    updateKey(listKey);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Chicken) other.collidedWithPlayer();
      if (other is Checkpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void updateKey(List<MyKeyEvent> keys) {
    horizontalMovement = 0;
    horizontalMovement += keys.contains(MyKeyEvent.keyLeft) ? -1 : 0;
    horizontalMovement += keys.contains(MyKeyEvent.keyRight) ? 1 : 0;

    hasJumped = keys.contains(MyKeyEvent.keyUp);
    hasDoubleJumped = hasJumped && !isOnGround && !doubleJumped;
    if (isClimbing && horizontalMovement != 0) {
      isClimbing = horizontalClimbing == horizontalMovement;
      horizontalClimbing = isClimbing ? horizontalClimbing : 0;
    }
  }

  void updateNewStartPosition(Vector2 pos) {
    position = pos;
    startingPosition = pos;
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    doubleJumpAnimation = _spriteAnimation('Double Jump', 6);
    fallingAnimation = _spriteAnimation('Fall', 1);
    wallJumpAnimation = _spriteAnimation('Wall Jump', 5);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);

    // List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.doubleJump: doubleJumpAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.wallJump: wallJumpAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
    };

    // Set current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$state (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
        loop: false,
      ),
    );
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // Check if moving, set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    // check if Falling set to falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    // Checks if jumping, set to jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    // Check if doubleJump
    if (velocity.y < 0 && doubleJumped && !isClimbing) playerState = PlayerState.doubleJump;

    if (isClimbing) playerState = PlayerState.wallJump;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped) {
      if (isClimbing && !isOnGround) {
        _playerClimbing(dt);
      } else if (hasDoubleJumped) {
        _playerDoubleJump(dt);
      } else if (isOnGround) {
        _playerJump(dt);
      }
    }

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
    isClimbing = false;
  }

  void _playerDoubleJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasDoubleJumped = false;
    hasJumped = false;
    isClimbing = false;
    doubleJumped = true;
  }

  void _playerClimbing(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    horizontalMovement = -horizontalClimbing;
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
    doubleJumped = false;
    _playerJump(dt);
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            hasDoubleJumped = false;
            hasJumped = false;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            if (!block.isBound) {
              horizontalClimbing = 1;
              isClimbing = true;
              desClimbing = Vector2(position.x, block.y + block.height - height / 2);
            }
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            hasDoubleJumped = false;
            hasJumped = false;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            if (!block.isBound) {
              horizontalClimbing = -1;
              isClimbing = true;
              desClimbing = Vector2(position.x, block.y + block.height - height / 2);
            }
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    if (!isClimbing) {
      velocity.y += _gravity;
      velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
      position.y += velocity.y * dt;
    } else {
      if (position.y > desClimbing.y || position.x - desClimbing.x != 0) {
        isClimbing = false;
        velocity.y += _gravity;
        position.y += velocity.y * dt;
      } else {
        velocity.y = 0.15 * _terminalVelocity;
        if (horizontalClimbing == horizontalMovement) {
          velocity.y += 0.1 * _terminalVelocity;
        }
        position.y += velocity.y * dt;
      }
    }
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            doubleJumped = false;
            isClimbing = false;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            doubleJumped = false;
            isClimbing = false;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
            isClimbing = false;
          }
        }
      }
    }
  }

  void _respawn() async {
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
    Duration canMoveDuration = Duration(milliseconds: _timeNotMove);
    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 1);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedwithEnemy() {
    _respawn();
  }
}
