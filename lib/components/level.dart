import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/background_tile.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/enemies/chicken.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/items/fruit.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/traps/saw.dart';
import 'package:pixel_adventure/components/traps/saw_chain.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Level extends World with HasGameRef<PixelAdventure> {
  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));

    add(level);

    _scrollingBackground();
    _setupCamera();
    _spawningObjects();
    _addCollisions();

    return super.onLoad();
  }

  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');

    if (backgroundLayer != null) {
      final backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor');
      final backgroundTile = BackgroundTile(
        color: backgroundColor ?? 'Gray',
        size: Vector2(level.width, level.height),
        position: Vector2(0, 0)
      );
      add(backgroundTile);
    }
  }

  void _spawningObjects() {
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if (spawnPointsLayer != null) {
      for (final spawnPoint in spawnPointsLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.updateNewStartPosition(Vector2(spawnPoint.x, spawnPoint.y));
            player.scale.x = 1;
            break;
          case 'Fruit':
            final fruit = Fruit(
              fruit: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(fruit);
            break;
          case 'Saw':
            _addTrapsSaw(spawnPoint);
            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height));
            add(checkpoint);
            break;
          case 'Chicken':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final chicken = Chicken(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg,
              offPos: offPos,
            );
            add(chicken);
            break;
          default:
        }
      }
      add(player);
    }
  }

  void _addTrapsSaw(TiledObject spawnPoint) {
    final isShowLine = spawnPoint.properties.getValue('isShowLine');
    final isVertical = spawnPoint.properties.getValue('isVertical');
    final offNeg = spawnPoint.properties.getValue('offNeg');
    final offPos = spawnPoint.properties.getValue('offPos');
    final pos = Vector2(spawnPoint.x, spawnPoint.y);
    final sizeSaw = Vector2(spawnPoint.width, spawnPoint.height);
    final saw = Saw(
        isVertical: isVertical,
        offNeg: offNeg,
        offPos: offPos,
        position: pos,
        size: sizeSaw);

    if (isShowLine == true && offNeg + offPos > 0) {
      final centerPos = pos + sizeSaw * 1.5 / 4;

      if (isVertical == true) {
        double h = sizeSaw.y / 4;
        for (double posY = saw.rangeNeg;
            posY <= saw.rangePos + sizeSaw.y - h;
            posY += h) {
          add(SawChain(
              position: Vector2(centerPos.x, posY), size: Vector2.all(h)));
        }
      } else {
        double w = sizeSaw.x / 4;
        for (double posX = saw.rangeNeg;
            posX <= saw.rangePos + sizeSaw.x - w;
            posX += w) {
          add(SawChain(
              position: Vector2(posX, centerPos.y), size: Vector2.all(w)));
        }
      }
    }

    add(saw);
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isPlatform: true
            );
            collisionBlocks.add(platform);
            add(platform);
            break;
          case 'Bound':
            final bound = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isBound: true
            );
            collisionBlocks.add(bound);
            add(bound);
            break;
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collisionBlocks.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks;
  }

  void _setupCamera() {
    game.cam.world = this;
    game.cam.follow(player, maxSpeed: 250);
    game.cam.setBounds(
      Rectangle.fromLTRB(
        game.fixedResolution.x / 2,
        game.fixedResolution.y / 2,
        level.width - game.fixedResolution.x / 2,
        level.height - game.fixedResolution.y / 2,
      ),
    );
  }
}
