import hangover

import card as crd
import cursor as cur
import camera as cam
import file

import textureData

import options
import sequtils
import sets

import glfw

type
  ActionKind* = enum
    delete
    create
    addWire
    delWire
    toggle
    move
    size

  Action* = object
    case kind*: ActionKind
    of addWire, delWire:
      wireStart: Card
      wireStop: Card
    of delete:
      deleteCards*: seq[Card]
    of create:
      card*: Card
    of toggle:
      toggleCards*: seq[Card]
    of move:
      moveCards*: seq[Card]
      moveOffset*: Vector2
    of size:
      sizeCard*: Card
      sizeOffset*: Vector2

createEvent[Action] eventDoAction
createEvent[void] eventUndoAction 
createEvent[void] eventRedoAction

var
  history*: seq[Action]
  next: int
 
proc call*(a: Action) =
  case a.kind
  of delete:
    cards.keepItIf it notin a.deleteCards
  of create:
    cards &= a.card
  of move:
    for c in a.moveCards:
      c.position = c.position.offset(a.moveOffset)
  of toggle:
    for c in a.toggleCards:
      c.done = not c.done
  of size:
    a.sizeCard.position = a.sizeCard.position.sizeOffset(a.sizeOffset)
  of addWire:
    a.wireStart.wires.incl a.wireStop
  of delWire:
    a.wireStart.wires.excl a.wireStop

proc unCall*(a: Action) =
  case a.kind
  of delete:
    cards &= a.deleteCards
  of create:
    cards.keepItIf it != a.card
  of move:
    for c in a.moveCards:
      c.position = c.position.offset(-a.moveOffset)
  of toggle:
    for c in a.toggleCards:
      c.done = not c.done
  of size:
    a.sizeCard.position = a.sizeCard.position.sizeOffset(-a.sizeOffset)
  of addWire:
    a.wireStart.wires.excl a.wireStop
  of delWire:
    a.wireStart.wires.incl a.wireStop

proc init*(h: var seq[Action], textures: TextureAtlas) =
  discard

eventDoAction.listen do (a: Action) -> bool:
  a.call

  history.setLen next
  history &= a
  next += 1 

eventUndoAction.listen do () -> bool:
  if next == 0:
    echo "cant undo"
    return

  history[next - 1].uncall
  next -= 1

eventRedoAction.listen do () -> bool:
  if next + 1 > history.len:
    echo "cant redo"
    return
  
  history[next].call
  next += 1

eventPressKey.listen do (key: Key) -> bool:
  if key == keyLeft:
    camera.target.x += 5
  elif key == keyRight:
    camera.target.x -= 5
  elif key == keyUp:
    camera.target.y += 5
  elif key == keyDown:
    camera.target.y -= 5
  elif key == keyZ:
    if globalCtx.window.isKeyDown(keyLeftControl) or
       globalCtx.window.isKeyDown(keyRightControl):
      if globalCtx.window.isKeyDown(keyLeftShift) or
         globalCtx.window.isKeyDown(keyRightShift):
        eventRedoAction.send 
        for c in cards:
          c.selected = false
      else:
        eventUndoAction.send 
        for c in cards:
          c.selected = false
  elif key == keyO:
    if globalCtx.window.isKeyDown(keyLeftControl) or
       globalCtx.window.isKeyDown(keyRightControl):
      readCIKFile("plan.nn")
      history = @[]
      next = 0
  elif key == keyS:
    if globalCtx.window.isKeyDown(keyLeftControl) or
       globalCtx.window.isKeyDown(keyRightControl):
      writeCIKFile("tmp.nn")
  elif key == keySpace:
    var toggles: seq[Card]
      
    for c in cards.mitems:
      if c.selected:
        toggles &= c

      if c.insert:
        return
  
    eventDoAction.send Action(
      kind: toggle,
      toggleCards: toggles,
    )

  elif key == keyDelete:
    var deletes: seq[Card]
      
    for c in cards:
      if c.selected:
        deletes &= c

    eventDoAction.send Action(
      kind: delete,
      deleteCards: deletes,
    )

eventMouseClick.listen do (btn: int) -> bool:
  if btn == 1:
    if cursor.focused.isSome():
      return

    eventDoAction.send Action(
      kind: create,
      card: Card(
        text: "New Card",
        position: newRect(
          cursor.target.location,
          newVector2(10, 1),
        ),
        wires: initHashSet[Card](),
      ),
    )

eventCursorMove.listen do (offset: Vector2) -> bool:
  var moves: seq[Card] 

  for c in cards:
    if c.selected:
      moves &= c
  
  if moves.len == 0:
    return

  eventDoAction.send Action(
    kind: move,
    moveCards: moves,
    moveOffset: offset,
  )

eventCursorSize.listen do (offset: Vector2) -> bool:
  var sizes: Card

  for c in cards:
    if c.selected:
      sizes = c

  if sizes == nil:
    return

  eventDoAction.send Action(
    kind: size,
    sizeCard: sizes,
      sizeOffset: offset,
  )

eventWireCards.listen do (data: tuple[start, stop: Vector2]) -> bool:
  var
    start {.cursor.}: Card
    stop {.cursor.}: Card

  for c in cards:
    if data.start in c.position:
      start = c
    if data.stop in c.position:
      stop = c

  if start == nil or stop == nil or start == stop: return

  if stop in start.wires:
    eventDoAction.send Action(
      kind: delWire,
      wireStart: start,
      wireStop: stop,
    )
  else:
    eventDoAction.send Action(
      kind: addWire,
      wireStart: start,
      wireStop: stop,
    )
  
