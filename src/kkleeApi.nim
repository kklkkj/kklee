when not defined js:
  {.fatal: "This module only works on the JavaScipt platform".}

import std/[strutils, sequtils, dom, math]

template importUpdateFunction(name: untyped;
    procType: type = proc(): void) =
  let `update name`* {.importc: "window.kklee.$1"inject.}: procType
  var `afterUpdate name`* {.importc: "window.kklee.$1"inject.}: procType

importUpdateFunction(LeftBox)
importUpdateFunction(RightBoxBody, proc(fx: int): void)
importUpdateFunction(Renderer, proc(b: bool): void)
importUpdateFunction(Warnings)
importUpdateFunction(UndoButtons)
importUpdateFunction(ModeDropdown)

var afterNewMapObject* {.importc: "window.kklee.$1".}: proc(): void
let saveToUndoHistory* {.importc: "window.kklee.$1".}: proc(): void

template importCurrentThing(name: untyped) =
  let `getCurrent name`* {.importc: "window.kklee.$1"inject.}: proc(): int
  let `setCurrent name`* {.importc: "window.kklee.$1"inject.}: proc(i: int)

importCurrentThing(Body)
importCurrentThing(Spawn)
importCurrentThing(CapZone)

proc setColourPickerColour*(colour: int) {.importc: "window.kklee.$1".}

type
  MapPosition* = array[2, float]
  MapData* = ref object
    v*: int # Version
    m*: MapMetaData
    spawns*: seq[MapSpawn]
    capZones*: seq[MapCapZone]
    physics*: MapPhysics
  MapMetaData* = ref object
    n*, a*, date*, mo*: cstring # Name, author, date, mode
    rxn*, rxa*: cstring         # Original name and author
    dbid*, dbv*, authid*, rxdb*, rxid*: int
    pub*: bool
    cr*: seq[cstring]           # Credits

  MapSpawn* = ref object
    n*: cstring
    priority*: int
    f*, r*, b*, gr*, ye*: bool
    x*, y*, xv*, yv*: float
  MapCapZone* = ref object
    n*: cstring
    ty*: MapCapZoneType
    i*: int   # Fixture ID
    l*: float # Time
  MapCapZoneType* = enum
    cztNormal = 1, cztRed, cztBlue, cztGreen, cztYellow

  MapPhysics* = ref object
    ppm*: float    # Player radius = ppm
    fixtures*: seq[MapFixture]
    shapes*: seq[MapShape]
    bodies*: seq[MapBody]
    bro*: seq[int] # Array of body IDs
    joints*: seq[MapJoint]

  MapBody* = ref object
    n*: cstring
    btype* {.extern: "type".}: cstring # Type is a keyword in Nim
    a*, ad*, av*: float                # Angle, drag, velocity
    de*, fric*, ld*, re*: float        # Density, friction, linear drag,
                                       # bounciness
    f_1*, f_2*, f_3*, f_4*, f_p*: bool # Collision groups enabled
    f_c*: MapBodyCollideGroup          # Collision group
    fr*, fricp*, bu*: bool             # Fixed rotation, fric players,
                                       # anti-tunnel
    p*, lv*: MapPosition               # Position, linear velocity
    fx*: seq[int]                      # Fixture IDs
    cf*: MapBodyCf
  MapBodyCf* = ref object # Constant force
    x*, y*, ct*: float    # x, y, torque
    w*: bool              # Force direction - true: absolute, false: relative
  MapBodyCollideGroup* {.pure.} = enum
    A = 1, B, C, D
  MapBodyType* = enum
    btStationary = "s", btDynamic = "d", btKinematic = "k"

  MapFixture* = ref object
    n*: cstring
    d*, ng*, np*, fp*, ig*: bool # Death, no grapple, no physics, fric players,
                                 # inner grapple
    de*, re*, fr*: float         # Set to Nan for no value
    f*: int                      # Colour
    sh*: int

  MapShapeType* = enum
    stypeBx = "bx", stypeCi = "ci", stypePo = "po"
  MapShape* = ref object
    stype* {.exportc: "type".}: cstring
    c*: MapPosition
    a* {.exportc: "a".}: float

    sk* {.exportc: "sk".}: bool  # Shrink, not available for polygons

    bxW* {.exportc: "w".}: float
    bxH* {.exportc: "h".}: float

    ciR* {.exportc: "r".}: float

    poS* {.exportc: "s".}: float # Scale
    poV* {.exportc: "v".}: seq[MapPosition]

  MapJoint* = ref object
    ba*, bb*: int # ba: Joint body, bb: attached body, -1 if none

func shapeType*(s: MapShape): MapShapeType = parseEnum[MapShapeType]($s.stype)

var mapObject* {.importc: "window.kklee.mapObject".}: MapData

proc fxShape*(fxo: MapFixture): MapShape = mapObject.physics.shapes[fxo.sh]
proc getFx*(fxId: int): MapFixture = mapObject.physics.fixtures[fxId]
proc getBody*(bi: int): MapBody = mapObject.physics.bodies[bi]

template x*(arr: MapPosition): untyped = arr[0]
template `x=`*(arr: MapPosition; v): untyped = arr[0] = v
template y*(arr: MapPosition): untyped = arr[1]
template `y=`*(arr: MapPosition; v): untyped = arr[1] = v

func rotatePoint*(p: MapPosition; a: float): MapPosition =
  [
    p.x * cos(a) - p.y * sin(a),
    p.x * sin(a) + p.y * cos(a)
  ]

template moph*: untyped = mapObject.physics

proc deleteFx*(fxId: int) =
  let shId = fxId.getFx.sh
  moph.fixtures.delete fxId
  moph.shapes.delete shId
  for b in moph.bodies:
    b.fx.keepItIf it != fxId
    for f in b.fx.mitems:
      if f > fxId: dec f
  for c in mapObject.capZones.mitems:
    if c.i == fxId: c.i = -1
    if c.i > fxId: dec c.i
  for f in moph.fixtures.mitems:
    if f.sh > shId: dec f.sh

proc deleteBody*(bId: int) =
  while bId.getBody.fx.len > 0:
    deleteFx bId.getBody.fx[0]
  moph.bodies.delete bId
  moph.bro.keepItIf it != bId
  for otherBId in moph.bro.mitems:
    if otherBId > bId: dec otherBId
  block:
    var jId = 0
    while jId < moph.joints.len:
      let j = moph.joints[jId]
      if j.ba == bId:
        moph.joints.delete jId
        continue
      if j.bb == bId:
        j.bb = -1
      if j.ba > bId:
        dec j.ba
      if j.bb > bId:
        dec j.bb
      inc jId

var editorPreviewTimeMs* {.importc: "window.kklee.$1".}: float

func copyObject*[T: ref](x: T): T =
  proc stringify(_: T): cstring {.importc: "window.JSON.stringify".}
  proc parse(_: cstring): T {.importc: "window.JSON.parse".}
  x.stringify.parse

let jsNull* {.importc: "null".}: float

proc docElemById*(s: cstring): Element =
  document.getElementById(s)

proc setEditorExplanation*(text: string) =
  docElemById("mapeditor_midbox_explain").innerText = text

proc mathExprJsRandom*(_: seq[float]): float {.importc: "window.Math.random".}