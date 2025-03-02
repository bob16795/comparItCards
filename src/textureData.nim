import hangover

const
  SHEET8X_WIDTH = 1
  SHEET8X_HEIGHT = 12
  SHEET8X_PADDING = 1 / 10
  SHEET8X_SCALE_X = 1 / SHEET8X_WIDTH
  SHEET8X_SCALE_Y = 1 / SHEET8X_HEIGHT

  SHEET32X_WIDTH = 1
  SHEET32X_HEIGHT = 3
  SHEET32X_PADDING = 1 / 42
  SHEET32X_SCALE_X = 1 / SHEET32X_WIDTH
  SHEET32X_SCALE_Y = 1 / SHEET32X_HEIGHT

template Sprite8x*(x, y): Rect =
  newRect((x + SHEET8X_PADDING) * SHEET8X_SCALE_X,
          (y + SHEET8X_PADDING) * SHEET8X_SCALE_Y,
          (1 - (SHEET8X_PADDING * 2)) * SHEET8X_SCALE_X,
          (1 - (SHEET8X_PADDING * 2)) * SHEET8X_SCALE_Y)

template Center8x*(ox, oy, x, y, w, h: int): Rect =
  newRect((x + 1) * SHEET8X_PADDING * SHEET8X_SCALE_X,
          (y + 1) * SHEET8X_PADDING * SHEET8X_SCALE_Y,
          w * SHEET8X_PADDING * SHEET8X_SCALE_X,
          h * SHEET8X_PADDING * SHEET8X_SCALE_Y).offset(newVector2(ox * SHEET8X_SCALE_X, oy * SHEET8X_SCALE_Y))

template Scale8x*(scale: float32): Vector2 =
  newVector2(scale / SHEET8X_SCALE_X,
             scale / SHEET8X_SCALE_Y)

template Scale32x*(scale: float32): Vector2 =
  newVector2(scale / SHEET32X_SCALE_X,
             scale / SHEET32X_SCALE_Y)

template Sprite32x*(x, y): Rect =
  newRect((x + SHEET32X_PADDING) * SHEET32X_SCALE_X,
          (y + SHEET32X_PADDING) * SHEET32X_SCALE_Y,
          (1 - (SHEET32X_PADDING * 2)) * SHEET32X_SCALE_X,
          (1 - (SHEET32X_PADDING * 2)) * SHEET32X_SCALE_Y)

template Center32x*(ox, oy, x, y, w, h: int): Rect =
  newRect((x + 1) * SHEET32X_PADDING * SHEET32X_SCALE_X,
          (y + 1) * SHEET32X_PADDING * SHEET32X_SCALE_Y,
          w * SHEET32X_PADDING * SHEET32X_SCALE_X,
          h * SHEET32X_PADDING * SHEET32X_SCALE_Y).offset(newVector2(ox * SHEET32X_SCALE_X, oy * SHEET32X_SCALE_Y))
