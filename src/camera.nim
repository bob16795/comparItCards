import hangover

import options
import math

import textureData

import config as cfg

type
  Camera* = object
    positioni*: Vector2
    target*: Vector2

    zoom*: float32
    zoomTrg*: float32

    screenSize*: Vector2
    mousePos*: Vector2

    drag: Option[tuple[mouseStart, camStart: Vector2]]

var
  camera*: Camera
  gridSprite: Sprite
  gridXSprite: Sprite
  gridYSprite: Sprite

const
  GRID_SCALE = 64
  CAM_SPEED = 0.1
  GRID_SPRITE_SIZE = 5

proc unit*(c: Camera): float32 = 
  c.zoom * GRID_SCALE

proc position*(c: Camera): Vector2 = 
  c.positioni + (c.screenSize * 0.5) / camera.unit

eventMouseMove.listen do (pos: Vector2) -> bool:
  camera.mousePos = pos / camera.unit

  if camera.drag.isSome:
    let drag = camera.drag.get()
    camera.target = drag.camStart - (drag.mouseStart - camera.mousePos)

eventMouseClick.listen do (btn: int) -> bool:
  case btn
  of 2:
    camera.drag = some((mouseStart: camera.mousePos, camStart: camera.target))
  else: discard

eventMouseRelease.listen do (btn: int) -> bool:
  case btn
  of 2: 
    camera.drag = none[tuple[mouseStart: Vector2, camStart: Vector2]]()
  else: discard

eventMouseScroll.listen do (offset: Vector2) -> bool:
  camera.zoomTrg += offset.y / 15
  camera.zoomTrg = camera.zoomTrg.clamp(0.25, 2.5)

eventResize.listen do (size: Point) -> bool:
  camera.screenSize = size.toVector2

# Camera update
eventUpdate.listen do (dt: float32) -> bool:
  if dt >= CAM_SPEED: camera.zoom = camera.zoomTrg
  else: camera.zoom += (camera.zoomTrg - camera.zoom) / CAM_SPEED * dt.float32 
  
  if dt >= CAM_SPEED: camera.positioni = camera.target
  else: camera.positioni += (camera.target - camera.positioni) / CAM_SPEED * dt.float32 

proc init*(self: var Camera, textures: TextureAtlas) =
  self.zoom = 1.0
  self.zoomTrg = 1.0

  gridSprite = newSprite(textures["32x"], Sprite32x(0, 0))
  gridXSprite = newSprite(textures["32x"], Sprite32x(0, 1))
  gridYSprite = newSprite(textures["32x"], Sprite32x(0, 2))

proc draw*(self: Camera) =
  drawRectFill(
    newRect(
      newVector2(0),
      self.screenSize,
    ),
    config.scheme[background]
  )

  let unit = self.unit

  var y_axis = false
  var x = ((self.position.x mod GRID_SPRITE_SIZE) - GRID_SPRITE_SIZE) * unit
  while x - unit * GRID_SPRITE_SIZE < self.screenSize.x + self.position.x:
    gridXSprite.draw(
      newRect(
        x.float32,
        (self.position.y - 1) * unit,
        unit * GRID_SPRITE_SIZE,
        unit * GRID_SPRITE_SIZE,
      ),
      color = config.scheme[grid],
    )

    var y = ((self.position.y mod GRID_SPRITE_SIZE) - GRID_SPRITE_SIZE) * unit
    while y - unit * GRID_SPRITE_SIZE < self.screenSize.y + self.position.y:
      if not y_axis:
        gridYSprite.draw(
          newRect(
            (self.position.x - 1) * unit,
            y.float32,
            unit * GRID_SPRITE_SIZE,
            unit * GRID_SPRITE_SIZE,
          ),
          color = config.scheme[grid],
        )
      gridSprite.draw(
        newRect(
          x.float32,
          y.float32,
          unit * GRID_SPRITE_SIZE,
          unit * GRID_SPRITE_SIZE,
        ),
        color = config.scheme[grid],
      )

      y += unit * GRID_SPRITE_SIZE 
    y_axis = true
    x += unit * GRID_SPRITE_SIZE
