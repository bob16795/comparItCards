import hangover
import json

import std/enumerate

import card as crd
import camera as cam
import tables
import sets

proc writeCIKFile*(path: string) =
  var cardData = %*[]
  var wires = %*[]
  var map: Table[Card, string]
  for idx, c in enumerate(cards):
    cardData &= %*{
      "id": $idx,
      "kind": "Todo",
      "text": c.text,
      "location": {
        "x": c.position.x,
        "y": c.position.y,
        "w": c.position.width,
        "h": c.position.height,
      },
      "done": c.done,
    }
    map[c] = $idx 
  
  for idx, c in enumerate(cards):
    for w in c.wiresVis:
      wires &= %*{
        "end": $idx,
        "start": map[w],
      }

  let jsonData = %*{
    "wires": wires,
    "cards": carddata,
    "camera": {
      "zoom": camera.zoomTrg,
      "position": {
        "x": camera.target.x * -1,
        "y": camera.target.y * -1,
      }
    }
  }

  var output = open(path, fmWrite)
  try:
    output.write(pretty(jsonData))
  finally:
    output.close()

proc readCIKFile*(path: string) =
  var input = open(path, fmRead)
  let json = parseJson(input.readAll())

  input.close

  var map: Table[string, Card]

  cards = @[]

  for c in json["cards"]:
    let l = c["location"]
    
    case c["kind"].getStr()
    of "Todo":
      let card = Card(
        wires: initHashSet[Card](),
        position: newRect(
          l["x"].getFloat, l["y"].getFloat,
          l["w"].getFloat, l["h"].getFloat,
        ),
        text: c["text"].getStr,
        done: c["done"].getBool,
      )
      cards &= card
      map[c["id"].getStr] = card

  for w in json["wires"]:
    let
      stop = w["end"].getStr()
      start = w["start"].getStr()

    if start notin map or stop notin map: continue

    map[stop].wires.incl map[start]

  if "camera" in json:
    camera.zoom = json["camera"]["zoom"].getFloat(1)
    camera.zoomTrg = json["camera"]["zoom"].getFloat(1)

    camera.positioni.x = json["camera"]["position"]["x"].getFloat(0) * -1
    camera.positioni.y = json["camera"]["position"]["y"].getFloat(0) * -1
    camera.target.x = json["camera"]["position"]["x"].getFloat(0) * -1
    camera.target.y = json["camera"]["position"]["y"].getFloat(0) * -1

  
