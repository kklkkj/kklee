import
  std/[sugar, strutils, algorithm, strformat, dom, math],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr,
  kkleeApi, bonkElements

var
  selectedFixtures*: seq[MapFixture]
  fixturesBody*: MapBody

type boolPropValue = enum
  bpSame, bpTrue, bpFalse

proc removeDeletedFixtures =
  var i = 0
  while i < selectedFixtures.len:
    let fx = selectedFixtures[i]
    if moph.fixtures.find(fx) == -1:
      selectedFixtures.delete i
    else:
      inc i

proc shapeMultiSelectElementBorders* =
  let
    shapeElements = document
      .getElementById("mapeditor_rightbox_shapetablecontainer")
      .getElementsByClassName("mapeditor_rightbox_table_shape_headerfield")
      .reversed
    body = getCurrentBody().getBody
  for i, se in shapeElements:
    if selectedFixtures.find(body.fx[i].getFx) == -1:
      se.style.border = ""
    else:
      se.style.border = "4px solid blue"

proc tfsCheckbox(inp: var boolPropValue): VNode =
  let colour = case inp
    of bpTrue: "#59d65e"
    of bpFalse: "#d65959"
    of bpSame: "#d6bd59"
  return buildHtml tdiv(style = ("width: 10px; height: 10px; margin: 3px; " &
    "border: 2px solid #111111; background-color: {colour}").fmt.toCss
  ):
    proc onClick =
      inp = case inp
        of bpSame: bpTrue
        of bpTrue: bpFalse
        of bpFalse: bpSame

proc prop(name: string; field: VNode): VNode =
  buildHtml: tdiv(style =
    "display:flex; flex-flow: row wrap; justify-content: space-between"
    .toCss):
    text name
    field

proc shapeMultiSelectSwitchPlatform* =
  if getCurrentBody().getBody != fixturesBody:
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  fixturesBody = getCurrentBody().getBody

proc floatNop(f: float): float = f

proc shapeMultiSelectEdit: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):

  ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
    li text "Shift+click shape name fields to select shapes"
    li text """Note: you will have to reselect the platform to see changes
made by multiselect"""
    li text """Variables: x is current value, i is index in list of
selected shapes (the first shape you selected will have i=0, the next one
i=1, i=2, etc)"""
    li text "Arithmetic, such as x*2+50, will be evaluated"

  var appliers: seq[(int, var MapFixture) -> void]

  template floatProp(
    name: string; mapFxProp: untyped;
    inpToProp = floatNop;
    propToInp = floatNop;
  ): untyped =
    let
      inpToPropF = inpToProp
      propToInpF = propToInp
    var inp {.global.}: string = "x"

    appliers.add proc (i: int; fx {.inject.}: var MapFixture) =
      let evtor = newEvaluator()
      evtor.addVars {"x": propToInpF(mapFxProp), "i": i.float}
      var res = inpToPropF(evtor.eval inp)
      res = res.clamp(-1e6, 1e6)
      if res == NaN: res = 0
      mapFxProp = res

    buildHtml:
      prop name, bonkInput(inp, proc(parserInput: string): string =
        let evtor = newEvaluator()
        evtor.addVars {"x": 0.0, "i": 0.0}
        discard evtor.eval parserInput
        return parserInput
      , nil, s=>s)

  template boolProp(name: string; mapFxProp: untyped): untyped =
    var inp {.global.}: boolPropValue
    appliers.add proc(i: int; fx {.inject.}: var MapFixture) =
      case inp
      of bpFalse: mapFxProp = false
      of bpTrue: mapFxProp = true
      of bpSame: discard
    buildHtml:
      prop name, tfsCheckbox(inp)

  template colourChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: int = 0
    appliers.add proc(i: int; fx: var MapFixture) =
      if canChange:
        fx.f = inp
    buildHtml tdiv(style = "display: flex".toCss):
      checkbox(canChange)
      colourInput(inp)
  template nameChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: string = "Shape %i%"
    appliers.add proc(i: int; fx: var MapFixture) =
      if canChange:
        fx.n = inp.replace("%i%", $i).cstring
    buildHtml tdiv(style = "display: flex".toCss):
      checkbox(canChange)
      bonkInput(inp, s => s, nil, s => s)

  prop("Name", nameChanger())
  floatProp("x", fx.fxShape.c.x)
  floatProp("y", fx.fxShape.c.y)
  block:
    let
      d2r = proc(f: float): float = degToRad(f)
      r2d = proc(f: float): float = radToDeg(f)
    floatProp("Angle", fx.fxShape.a, d2r, r2d)
  floatProp("Rect width", fx.fxShape.bxW)
  floatProp("Rect height", fx.fxShape.bxH)
  floatProp("Circle radius", fx.fxShape.ciR)
  floatProp("Density", fx.de)
  floatProp("Bounciness", fx.re)
  floatProp("Friction", fx.fr)

  boolProp("No physics", fx.np)
  boolProp("No grapple", fx.ng)
  boolProp("Death", fx.d)

  prop("Colour", colourChanger())

  bonkButton "Apply", proc =
    removeDeletedFixtures()
    for i, f in selectedFixtures.mpairs:
      for a in appliers: a(i, f)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)


proc shapeMultiSelectCopy: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  var
    copyShapes {.global.}: seq[tuple[fx: MapFixture; sh: MapShape]]
    pasteAmount {.global.} = 1
  bonkButton "Copy shapes", proc =
    removeDeletedFixtures()
    copyShapes = @[]
    for fx in selectedFixtures:
      copyShapes.add (fx: fx.copyObject(), sh: fx.fxShape.copyObject())

  prop "Paste amount", bonkInput(pasteAmount, parseInt, nil, i => $i)
  bonkButton "Paste shapes", proc =
    shapeMultiSelectSwitchPlatform()
    proc copyFxSh(fx: MapFixture; sh: MapShape) =
      moph.shapes.add sh.copyObject()
      let newFx = fx.copyObject()
      moph.fixtures.add newFx
      newFx.sh = moph.shapes.high
      selectedFixtures.add newFx
      fixturesBody.fx.add moph.fixtures.high
    block outer:
      for _ in 1..pasteAmount:
        for (fx, sh) in copyShapes.mitems:
          if fixturesBody.fx.len > 100:
            break outer
          copyFxSh(fx, sh)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelectSelectAll: VNode = buildHtml tdiv:
  bonkButton "Select all", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = collect(newSeq):
      for fxid in fixturesBody.fx: fxid.getFx
    shapeMultiSelectElementBorders()
  bonkButton "Deselect all", proc =
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  bonkButton "Invert selection", proc =
    selectedFixtures = collect(newSeq):
      for fxid in fixturesBody.fx:
        let fx = fxid.getFx
        if fx notin selectedFixtures:
          fx
    shapeMultiSelectElementBorders()

proc shapeMultiSelectDelete: VNode =
  buildHtml bonkButton "Delete shapes", proc =
    for f in selectedFixtures:
      let fxid = moph.fixtures.find f
      if fxid == -1: continue
      deleteFx(fxid)
    saveToUndoHistory()
    selectedFixtures = @[]
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelect*: VNode =
  shapeMultiSelectSwitchPlatform()
  buildHtml(tdiv(
      style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
    shapeMultiSelectSelectAll()
    shapeMultiSelectEdit()
    shapeMultiSelectDelete()
    shapeMultiSelectCopy()
