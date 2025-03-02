import hangover

type
  SchemeColor* = enum
    background
    selection
    border
    error
    text
    grid
    todo
    done

  Config* = object
    scheme*: array[SchemeColor, Color]

var config*: Config

proc init*(c: var Config) =
  c.scheme[background] = newColor(42, 52, 64)
  c.scheme[selection] = newColor(200, 200, 200)
  c.scheme[border] = newColor(94, 129, 172)
  c.scheme[error] = newColor(191, 97, 106)
  c.scheme[todo] = newColor(129, 161, 193)
  c.scheme[done] = newColor(161, 184, 207)
  c.scheme[grid] = newColor(67, 76, 94)
  c.scheme[text] = newColor(76, 86, 106)
