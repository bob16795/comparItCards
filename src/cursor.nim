import hangover
import math

import textureData
import camera as cam
import config as cfg

import options

type
  Cursor = object
    position: Rect
    target*: Rect

    pin*: Option[Vector2]
    focused*: Option[Rect]
    canMove*: bool
    canSize*: bool
    moveDist*: Vector2
    
    time*: float32

    sprite*: UISprite

    wireStart*: Option[Vector2]
    clickTime: float32
    doubleClickTime: float32
    mouseDown: bool

createEvent[void] eventEndInput 
createEvent[void] eventCursorInput 
createEvent[Rect] eventCursorSelect
createEvent[Rect] eventCursorHover
createEvent[Rect] eventCursorWire
createEvent[Vector2] eventCursorMove
createEvent[Vector2] eventCursorSize
createEvent[tuple[start, stop: Vector2]] eventWireCards

var cursor*: Cursor

const
  CURSOR_SPEED* = 0.05

eventMouseClick.listen do (btn: int) -> bool:
  eventEndInput.send

  case btn
  of 0:
    cursor.mouseDown = true
    cursor.clickTime = 0

    cursor.pin = some(cursor.target.location)

    eventCursorSelect.send cursor.target
    eventCursorHover.send cursor.target
  of 1:
    eventCursorWire.send cursor.target
  else: discard

eventMouseRelease.listen do (btn: int) -> bool:
  case btn
  of 0: 
    if cursor.clickTime < 0.45:
      if cursor.doubleClicktime > 0:
        cursor.doubleClicktime = 0
        eventCursorInput.send
      else:
        cursor.doubleClicktime = 0.25

    cursor.mouseDown = false
    if cursor.pin.isSome() and
       cursor.canMove and
       cursor.moveDist != newVector2(0):
      if cursor.canSize:
        eventCursorSize.send cursor.moveDist
        cursor.moveDist = newVector2(0)
        cursor.canMove = false
      else:
        eventCursorMove.send cursor.moveDist
        cursor.moveDist = newVector2(0)
        cursor.canMove = false
    else:
      eventCursorSelect.send cursor.target
          
    cursor.pin = none[Vector2]()

    cursor.target = newRect(
      cursor.target.location + cursor.target.size - newVector2(1),
      newVector2(1),
    )
  of 1:
    if cursor.wireStart.isSome:
      eventWireCards.send (
        start: cursor.target.center,
        stop: cursor.wireStart.get,
      )

      cursor.wireStart = none[Vector2]()
  else: discard

eventMouseMove.listen do (pos: Vector2) -> bool:
  let
    unit = camera.unit
    target = round((pos / unit) - camera.position)

  if cursor.pin.isSome():
    if cursor.canMove:
      cursor.moveDist = target - cursor.pin.get()
    else:
      let
        a = newVector2(
          min(cursor.pin.get().x, target.x),
          min(cursor.pin.get().y, target.y),
        )
        b = newVector2(
          max(cursor.pin.get().x + 1, target.x),
          max(cursor.pin.get().y + 1, target.y),
        )

      cursor.target = newRect(
        a,
        (b.x - a.x).max(1),
        (b.y - a.y).max(1),
      )
        
      eventCursorSelect.send cursor.target
  else:
    cursor.target = newRect(
      target,
      newVector2(1),
    )

    eventCursorHover.send cursor.target

# Cursor update
eventUpdate.listen do (dt: float32) -> bool:
  cursor.sprite = cursor.sprite.scale(Scale8x(camera.unit))
  cursor.time += dt
  if cursor.time > 1.0:
    cursor.time -= 1.0
  if cursor.doubleClickTime > 0:
    cursor.doubleClickTime -= dt

  if cursor.mouseDown:
    cursor.clickTime += dt

  let
    target = if cursor.canSize: cursor.focused.get(cursor.target).sizeOffset(cursor.moveDist)
             else: cursor.focused.get(cursor.target).offset(cursor.moveDist)
    t1 = target.location
    t2 = target.location + target.size
  
  var
    p1 = cursor.position.location
    p2 = cursor.position.location + cursor.position.size

  if dt >= CURSOR_SPEED: 
    p1 = t1
    p2 = t2
  else:
    p1 += (t1 - p1) / CURSOR_SPEED * dt.float32
    p2 += (t2 - p2) / CURSOR_SPEED * dt.float32

  cursor.position = newRect(
    p1,
    p2 - p1,
  )

proc init*(self: var Cursor, textures: TextureAtlas) =
  self.sprite = newUISprite(textures["8x"], Sprite8x(0, 0), Center8x(0, 0, 3, 3, 2, 2)).scale(Scale8x(32))

proc draw*(self: Cursor) =
  if self.wirestart.isSome():
    drawLine(
      (self.wireStart.get() + camera.position) * camera.unit,
      (self.target.center + camera.position) * camera.unit,
      camera.unit * 1 / 8,
      config.scheme[selection],
    )

  let
    unit = camera.unit
    exp = (sin(cursor.time * 2 * PI) * 0.5 + 1.5) / 8 

  self.sprite.draw(
    self.position.offset(camera.position).expand(exp).scale(unit),
    color = config.scheme[selection],
  )
