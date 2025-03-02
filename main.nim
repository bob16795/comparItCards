import hangover

import content/files

import src/textureData
import src/camera as cam
import src/cursor as cur
import src/config as cfg
import src/action as act
import src/card as crd

import math

import glfw

var loadDone: bool

eventDrawLoad.listen do (loadData: LoadDrawEventData) -> bool:
  loadData.done = loadDone

eventInitialize.listen do () -> bool:
  var textures = newTextureAtlas()

  template loadAtlas(name: string, file: string) =
    let res = file.res
    textures &= newTextureDataMem(res.getPointer, res.size.cint, name)

  loadAtlas("8x", "8x.png")
  loadAtlas("32x", "32x.png")
  textures.pack

  cardFont = newFontMem(($res"pixel.ttf").cstring, res"pixel.ttf".size.cint, 64)

  history.init textures
  cursor.init textures
  camera.init textures
  cards.init textures
  
  config.init

  loadDone = true
  
  globalCtx.clearBuffer config.scheme[background]
  
  withGraphics:
    glDisable GL_DEPTH_TEST

eventDraw.listen do (inRatio: float32) -> bool:
  globalCtx.setShowMouse cmHidden

  camera.draw
  cards.draw
  cursor.draw
  
  finishDraw()

runGame(AppData(
  size: newPoint(640, 480),
  name: "ComparaCard",
  color: COLOR_BLACK,
))
