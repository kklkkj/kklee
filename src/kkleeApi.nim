import strutils

template importUpdateFunction(name: untyped;
    procType: type = proc: void) =
  let `update name`* {.importc: "window.kklee.$1"inject.}: procType
  var `afterUpdate name`* {.importc: "window.kklee.$1"inject.}: procType

importUpdateFunction(LeftBox)
importUpdateFunction(RightBoxBody, proc(fx: int): void)
importUpdateFunction(Renderer, proc(b: bool): void)
importUpdateFunction(Warnings)
importUpdateFunction(UndoButtons)
importUpdateFunction(ModeDropdown)

var afterNewMapObject* {.importc: "window.kklee.$1".}: proc(): void

template importCurrentThing(name: untyped) =
  let `getCurrent name`* {.importc: "window.kklee.$1"inject.}: proc(): int
  let `setCurrent name`* {.importc: "window.kklee.$1"inject.}: proc(): int

importCurrentThing(Body)
importCurrentThing(Spawn)
importCurrentThing(CapZone)

type
  MapPosition = array[2, float]
  MapData* = ref object
    v*: int
    m*: MapMetaData
    spawns*: seq[MapSpawn]
    capZones*: seq[MapCapZone]
    physics*: MapPhysics
  MapMetaData* = ref object
    n*, a*, rxn*, rxa*, date*, mo*: cstring
    dbid*, dbv*, authid*, rxdb*, rxid*: int
    pub*: bool
    cr*: seq[cstring]

  MapSpawn* = ref object
    n*: cstring
    priority*: int
    f*, r*, b*, gr*, ye*: bool
    x*, y*, xv*, yv*: float
  MapCapZone* = ref object
    n*: cstring
    ty*, i*: int
    l*: float

  MapPhysics* = ref object
    ppm*: float
    fixtures*: seq[MapFixture]
    shapes*: seq[MapShape]
    bodies*: seq[MapBody]
    bro*: seq[int]

  MapBody* = ref object
    n*: cstring
    btype* {.extern: "type".}: cstring # Type is a keyword in Nim
    a*, ad*, av*, de*, fric*, ld*, re*: float
    f_1*, f_2*, f_3*, f_4*, f_p*, fr*, fricp*: bool
    f_c*: int
    p*, lv*: MapPosition
    fx*: seq[int]
    cf*: MapBodyCf
  MapBodyCf* = ref object
    x*, y*, ct*: float
    w*: bool

  MapFixture* = ref object
    n*: cstring
    d*, ng*, np*, fp*: bool
    de*, re*, fr*: float # Set to Nan for no value
    f*: int              # Colour
    sh*: int

  MapShapeType* = enum
    stypeBx = "bx", stypeCi = "ci", stypePo = "po"
  MapShape* = ref object
    stype* {.exportc: "type".}: cstring
    c*: MapPosition

    bxW* {.exportc: "w".}: float
    bxH* {.exportc: "h".}: float
    bxA* {.exportc: "a".}: float
    bxSk* {.exportc: "sk".}: bool

    ciR* {.exportc: "r".}: float
    ciSk* {.exportc: "sk".}: bool

    poA* {.exportc: "a".}: float
    poS* {.exportc: "s".}: float
    poV* {.exportc: "v".}: seq[MapPosition]



proc shapeType*(s: MapShape): MapShapeType = parseEnum[MapShapeType]($s.stype)

var mapObject* {.importc: "window.kklee.mapObject".}: MapData

proc fxShape*(fxo: MapFixture): MapShape = mapObject.physics.shapes[fxo.sh]
proc getFx*(fxi: int): MapFixture = mapObject.physics.fixtures[fxi]
proc getBody*(bi: int): MapBody = mapObject.physics.bodies[bi]

template x*(arr: MapPosition): untyped = arr[0]
template y*(arr: MapPosition): untyped = arr[1]
