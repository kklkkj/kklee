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
    ty*, i*: int # Type, fixture ID
    l*: float    # Time

  MapPhysics* = ref object
    ppm*: float    # Player radius = ppm
    fixtures*: seq[MapFixture]
    shapes*: seq[MapShape]
    bodies*: seq[MapBody]
    bro*: seq[int] # Array of body IDs

  MapBody* = ref object
    n*: cstring
    btype* {.extern: "type".}: cstring # Type is a keyword in Nim
    a*, ad*, av*: float                # Angle, drag, velocity
    de*, fric*, ld*, re*: float        # Density, friction, linear drag,
                                       # bounciness
    f_1*, f_2*, f_3*, f_4*, f_p*: bool # Collision groups enabled
    f_c*: int                          # Collision group
    fr*, fricp*: bool                  # Fric, fric players
    p*, lv*: MapPosition               # Position, linear velocity
    fx*: seq[int]                      # Fixture IDs
    cf*: MapBodyCf
  MapBodyCf* = ref object # Constant force
    x*, y*, ct*: float    # x, y, torque
    w*: bool              # Force diretion - true: absolute, false: relative

  MapFixture* = ref object
    n*: cstring
    d*, ng*, np*, fp*: bool # Death, no grapple, no physics, fric players
    de*, re*, fr*: float    # Set to Nan for no value
    f*: int                 # Colour
    sh*: int

  MapShapeType* = enum
    stypeBx = "bx", stypeCi = "ci", stypePo = "po"
  MapShape* = ref object
    stype* {.exportc: "type".}: cstring
    c*: MapPosition
    a* {.exportc: "a".}: float

    bxW* {.exportc: "w".}: float
    bxH* {.exportc: "h".}: float
    bxSk* {.exportc: "sk".}: bool # Shrink

    ciR* {.exportc: "r".}: float
    ciSk* {.exportc: "sk".}: bool # Shrink

    poS* {.exportc: "s".}: float  # Scale
    poV* {.exportc: "v".}: seq[MapPosition]

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

var editorPreviewTimeMs* {.importc: "window.kklee.$1".}: float

func copyObject*[T: ref](x: T): T =
  proc stringify(_: T): cstring {.importc: "window.JSON.stringify".}
  proc parse(_: cstring): T {.importc: "window.JSON.parse".}
  x.stringify.parse

let jsNull* {.importc: "null".}: float

proc docElemById*(s: cstring): Element =
  document.getElementById(s)
