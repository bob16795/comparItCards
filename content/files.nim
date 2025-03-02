import nimres

const root = currentSourcePath() & "/.."

proc nimresLog(e: bool, s: string)

resToc(root, "content.bin",
  @[
    "8x.png",
    "32x.png",
  ]
)

import hangover

static:
  echo staticExec("cp content.bin ../content.bin")

proc nimresLog(e: bool, s: string) =
  if e:
    LOG_ERROR "nres->load", s
  else:
    LOG_INFO "nres->load", s
