import
  std/[sugar, strutils, algorithm, strformat, dom],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr,
  kkleeApi, bonkElements

let theEvaluator = newEvaluator()

var
  selectedFixtures*: seq[MapFixture]
  fixturesBody*: MapBody

type boolPropValue = enum
  bpSame, bpTrue, bpFalse

proc multiSelectElementBorders* =
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
  return buildHtml tdiv(style =
  "width: 10px; height: 10px; margin: 3px; border: 2px solid #111111; background-color: {colour}"
  .fmt.toCss):
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

  template floatProp(name: string; mapFxProp: untyped): untyped =
    var inp {.global.}: string = "x"
    appliers.add proc (i: int; fx {.inject.}: var MapFixture) =
      theEvaluator.addVars {"x": mapFxProp, "i": i.float}
      var res = theEvaluator.eval inp
      res = res.clamp(-1e6, 1e6)
      if res == NaN: res = 0
      mapFxProp = res
    buildHtml:
      prop name, bonkInput(inp, proc(parserInput: string): string =
        theEvaluator.addVars {"x": 0.0, "i": 0.0}
        discard theEvaluator.eval parserInput
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
    buildHtml tdiv(style =
      "display:flex; flex-flow: row wrap; justify-content: space-between"
      .toCss
      ):
      checkbox(canChange)
      colourInput(inp)

  floatProp("x", fx.fxShape.c.x)
  floatProp("y", fx.fxShape.c.y)
  floatProp("Angle (radians)", fx.fxShape.a)
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
    for i, f in selectedFixtures.mpairs:
      for a in appliers: a(i, f)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelectMove: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):

  var moveBody {.global.}: MapBody
  select:
    for bi in mapObject.physics.bro:
      option:
        text bi.getBody.n

    proc onInput(e: Event; n: VNode) =
      moveBody =
        mapObject.physics.bro[e.target.OptionElement.selectedIndex].getBody
    proc onMouseEnter(e: Event; n: VNode) =
      moveBody =
        mapObject.physics.bro[e.target.OptionElement.selectedIndex].getBody

  bonkButton("Move to platform", proc =
    block:
      var i = 0
      while i < fixturesBody.fx.len:
        let fxid = fixturesBody.fx[i]
        if fxid.getFx in selectedFixtures:
          moveBody.fx.add fxid
          fixturesBody.fx.delete i
        else:
          inc i

    setCurrentBody(mapObject.physics.bodies.find moveBody)
    fixturesBody = moveBody
    updateLeftBox()
    updateRenderer(true)
    updateRightBoxBody(-1)
    saveToUndoHistory()

  , moveBody.isNil)

var copyShapes: seq[tuple[fx: MapFixture; sh: MapShape]]

proc shapeMultiSelectCopy: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  bonkButton "Copy shapes", proc =
    copyShapes = @[]
    for fx in selectedFixtures:
      copyShapes.add (fx: fx.copyObject(), sh: fx.fxShape.copyObject())
  bonkButton "Paste shapes", proc =
    for (fx, sh) in copyShapes.mitems:
      moph.shapes.add sh.copyObject()
      let newFx = fx.copyObject()
      moph.fixtures.add newFx
      newFx.sh = moph.shapes.high
      selectedFixtures.add newFx
      fixturesBody.fx.add moph.fixtures.high
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelect*: VNode =
  if getCurrentBody().getBody != fixturesBody:
    selectedFixtures = @[]
    multiSelectElementBorders()
  fixturesBody = getCurrentBody().getBody

  buildHtml(tdiv(
      style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
    shapeMultiSelectEdit()

    bonkButton "Delete shapes", proc =
      for f in selectedFixtures:
        let fxid = moph.fixtures.find f
        if fxid == -1: continue
        deleteFx(fxid)
      saveToUndoHistory()
      selectedFixtures = @[]
      updateRenderer(true)
      updateRightBoxBody(-1)

    shapeMultiSelectMove()
    shapeMultiSelectCopy()



var
  duplicateFixture: MapFixture
  duplicateBody: MapBody
proc shapeMultiDuplicate*(fx: MapFixture; b: MapBody): VNode =
  duplicateFixture = fx
  duplicateBody = b
  buildHtml tdiv(style = "display: flex; flex-flow: column".toCss):
    var amount {.global.}: int = 1
    bonkInput(amount, parseInt, nil, i => $i)
    bonkButton "Duplicate", proc =
      selectedFixtures = @[duplicateFixture]
      fixturesBody = duplicateBody
      for _ in 0..amount:
        moph.shapes.add(copyObject duplicateFixture.fxShape)
        moph.fixtures.add(copyObject duplicateFixture)
        moph.fixtures[^1].sh = moph.shapes.high
        selectedFixtures.add moph.fixtures[^1]
        duplicateBody.fx.add moph.fixtures.high

      saveToUndoHistory()
      updateRenderer(true)
      updateRightBoxBody(-1)
