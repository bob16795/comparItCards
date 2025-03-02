import hangover

import textureData

import camera as cam
import cursor as csr
import config as cnf

import unicode

import options
import math
import sets

type
  Card* = ref object
    position*: Rect
    wires*: HashSet[Card]
    done*: bool
    progressVal*: float32
    text*: string
    insert*: bool

    selected*: bool

  CardTime* = object
    visited*: HashSet[Card]
    completion: float32
    time*: float32
    done: bool
    fail: bool

const CARD_SPEED*: float32 = 0.1

var
  cards*: seq[Card]
  cardFont*: Font

proc init*(self: seq[Card], textures: TextureAtlas) =
  discard

proc wiresVis*(self: Card): HashSet[Card] =
  result = initHashSet[Card]()
  for c in self.wires:
    if c in cards:
      result.incl c

proc progress*(self: Card, visited: HashSet[Card] = initHashSet[Card]()): CardTime

proc add*(self: var CardTime, other: Card, visited: HashSet[Card]) =
  if other in visited:
    self.fail = true
    return

  var tmp = visited
  tmp.incl other

  var other_progress = other.progress tmp

  self.completion += other_progress.completion
  self.time += other_progress.time
  self.fail = self.fail or other_progress.fail
  self.done = not self.fail and self.done and other_progress.done

proc viewPosition*(self: Card): Rect =
  result = if self.selected:
             if cursor.canSize: self.position.sizeOffset(cursor.moveDist)
             else: self.position.offset(cursor.moveDist)
           else: self.position
  result.width = result.width.max(1)
  result.height = result.height.max(1)

proc progress*(self: Card, visited: HashSet[Card] = initHashSet[Card]()): CardTime =
  if self.wiresVis.len == 0:
    return CardTime(
      time: self.position.width * self.position.height,  
      completion: if self.done: self.position.width * self.position.height  
                  else: 0.0,
      done: self.done,
    )
  result.visited = visited
  result.visited.incl self

  result.done = true
  for w in self.wiresVis:
    result.add(w, visited)

eventEndInput.listen do () -> bool: 
  for c in cards:
    c.insert = false

eventCursorInput.listen do () -> bool: 
  for c in cards:
    c.insert = c.selected

eventPressKey.listen do (key: Key) -> bool:
  case key
  of keyEscape:
    for c in cards:
      c.insert = false
  of keyEnter:
    for c in cards:
      c.insert = false
  of keyBackspace:
    for c in cards:
      if c.insert and c.text != "":
        c.text = c.text[0..^2]
  else: discard

eventPressChar.listen do (ch: Rune) -> bool:
  for c in cards:
    if c.insert:
      c.text &= $ch

eventCursorSelect.listen do (pos: Rect) -> bool:
  if cursor.focused.isSome:
    for c in cards.mitems:
      if c.position in pos and c.selected:
        return
    cursor.canMove = true

  for c in cards.mitems:
    c.selected = c.position in pos


eventCursorWire.listen do (pos: Rect) -> bool:
  for c in cards.mitems:
    if c.position in pos:
      c.selected = false 
      cursor.wireStart = some(c.position.center)

eventCursorHover.listen do (pos: Rect) -> bool:
  cursor.focused = none[Rect]()
  cursor.canMove = false
  cursor.canSize = false

  for c in cards.mitems:
    if c.position in pos:
      cursor.focused = some(c.viewPosition.expand(2 / 8))
      cursor.canMove = cursor.canMove or c.selected
      cursor.canSize = cursor.canSize or (
        cursor.target.x + 1 == c.position.x + c.position.width and
        cursor.target.y + 1 == c.position.y + c.position.height
      )

eventUpdate.listen do (dt: float32) -> bool: 
  for c in cards.mitems:
    let
      progress = c.progress
      target = progress.completion / progress.time

    if dt >= CARD_SPEED: c.progressVal = target
    else: c.progressVal += (target - c.progressVal) / CARD_SPEED * dt.float32 

proc drawWire*(self: Card) =
  let
    unit = camera.unit
    position = self.viewPosition

  for w in self.wiresVis:
    let
      other_position = w.viewPosition
    drawLine(
      position.offset(camera.position).scale(camera.unit).center,
      other_position.offset(camera.position).scale(camera.unit).center,
      camera.unit * 1 / 8, 
      config.scheme[selection]
    )


proc draw*(self: Card) =
  let
    unit = camera.unit
    position = self.viewPosition

  drawRectFill(
    position.offset(camera.position).scale(camera.unit),
    config.scheme[todo],
  )

  let progress = self.progress

  if progress.fail:
    drawRectFill(
      position.offset(camera.position).scale(camera.unit),
      config.scheme[error],
    )
  else:
    let
      progressRect = newRect(
        position.x,
        position.y,
        position.width * self.progressVal,
        position.height,
      )

    drawRectFill(
      progressRect.offset(camera.position).scale(camera.unit),
      config.scheme[done],
    )

  drawRectOutline(
    position.offset(camera.position).scale(camera.unit),
    int(camera.unit / 8),
    config.scheme[border],
  )
  drawRectOutline(
    newRect(
      position.location,
      newVector2(1),
    ).offset(camera.position).scale(camera.unit),
    int(camera.unit / 8),
    config.scheme[border],
  )

  let size = cardFont.sizeText(self.text) / 64.0
  cardFont.draw(
    self.text,
    position.offset(camera.position + newVector2(1.25, (1.0 - size.y) / 2)).scale(camera.unit).location, 
    config.scheme[SchemeColor.text],
    scale = camera.unit / 64,
    wrap = (self.position.width - 1.5) * camera.unit,
  )

  if cursor.time > 0.5 and self.insert:
    let text_start = position.offset(camera.position + newVector2(1.25, (1.0 - size.y) / 2)).scale(camera.unit).location
    let start = cardFont.sizeText(self.text) / 64.0
    drawLine(
      (position.location + camera.position + newVector2(1.25 + start.x, 3 / 16)) * camera.unit,
      (position.location + camera.position + newVector2(1.25 + start.x, 13 / 16)) * camera.unit,
      camera.unit / 16,
      config.scheme[SchemeColor.text],
    )

  if progress.done and not progress.fail:
    let
      a = (position.location + camera.position + newVector2(1 / 16)) * camera.unit
      b = a + newVector2(camera.unit * 14 / 16)
    drawLine(
      a, b,
      camera.unit / 8,
      config.scheme[border],
    )
    drawLine(
      newVector2(a.x, b.y),
      newVector2(b.x, a.y),
      camera.unit / 8,
      config.scheme[border],
    )


proc drawTop*(self: Card) =
  if self.selected:
    let
      unit = camera.unit
      position = self.viewPosition

    let exp = (sin(cursor.time * 2 * PI) * 0.5 + 1.5) / 8 
    
    drawRectOutline(
      position.offset(camera.position).expand(exp).scale(camera.unit),
      int(camera.unit / 8),
      config.scheme[selection],
    )

proc draw*(self: seq[Card]) =
  for card in self:
    card.drawWire
  
  for card in self:
    card.draw
  
  for card in self:
    card.drawTop
