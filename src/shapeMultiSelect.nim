import
  std/[sugar, strutils, sequtils, algorithm, dom, math, options],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

var
  selectedFixtures*: seq[MapFixture]
  fixturesBody*: MapBody

proc removeDeletedFixtures =
  var i = 0
  while i < selectedFixtures.len:
    let fx = selectedFixtures[i]
    if fx notin moph.fixtures:
      selectedFixtures.delete i
    else:
      inc i

proc shapeMultiSelectElementBorders* =
  removeDeletedFixtures()
  if getCurrentBody() == -1: return
  let
    shapeElements = document
      .getElementById("mapeditor_rightbox_shapetablecontainer")
      .getElementsByClassName("mapeditor_rightbox_table_shape_headerfield")
      .reversed
    body = getCurrentBody().getBody
  for i, se in shapeElements:
    let prevNode = se.previousSibling
    if not prevNode.isNil and prevNode.class ==
        "kkleeMultiSelectShapeIndexLabel":
      prevNode.remove()

    let selectedId = selectedFixtures.find(body.fx[i].getFx)
    if selectedId == -1:
      se.style.border = ""
    else:
      se.style.border = "4px solid blue"

      let indexLabel = document.createElement("span")
      indexLabel.innerText = $selectedId
      indexLabel.setAttr("style", "color: blue; font-size: 12px")
      indexLabel.class = "kkleeMultiSelectShapeIndexLabel"
      se.parentNode.insertBefore(indexLabel, se)

proc shapeMultiSelectSwitchPlatform* =
  if getCurrentBody() == -1: return
  if getCurrentBody().getBody != fixturesBody:
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  fixturesBody = getCurrentBody().getBody


proc shapeMultiSelectEdit: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):

  proc onMouseEnter =
    setEditorExplanation("""
[kklee]
Shift+click shape name fields to select shapes
Variables:
 - x is the current value
 - i is the index in list of selected shapes (the first shape you selected will have i=0, the next one i=1, i=2, etc)
Arithmetic, such as x*2+50, will be evaluated
 - n is number of shapes selected
List of supported functions:
https://yardanico.github.io/nim-mathexpr/mathexpr.html#what-is-supportedqmark
Additional function: rand() - random number between 0 and 1
    """)

  var appliers {.global.}: seq[(int, MapFixture) -> void]

  template floatProp(
    name: string; mapFxProp: untyped;
    inpToProp = floatNop;
    propToInp = floatNop;
  ): untyped =
    let
      inpToPropF = inpToProp
      propToInpF = propToInp
    var inp {.global.}: string = "x"

    once: appliers.add proc (i: int; fx {.inject.}: MapFixture) =
      mapFxProp = inpToPropF floatPropApplier(inp, i, selectedFixtures.len,
          propToInpF mapFxProp)

    buildHtml:
      prop name, floatPropInput(inp), inp != "x"

  template boolProp(name: string; mapFxProp: untyped): untyped =
    var inp {.global.}: boolPropValue
    once: appliers.add proc(i: int; fx {.inject.}: MapFixture) =
      case inp
      of tfsFalse: mapFxProp = false
      of tfsTrue: mapFxProp = true
      of tfsSame: discard
    buildHtml:
      prop name, tfsCheckbox(inp), inp != tfsSame

  template colourChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: int = 0
      isGradient {.global.} = false
      inp2 {.global.}: int = 0
      easingType {.global.} = easeNone
    once: appliers.add proc(i: int; fx: MapFixture) =
      if not canChange: return
      fx.f =
        if not isGradient: inp
        else:
          getGradientColourAt(inp, inp2, i / selectedFixtures.high, easingType)

    let
      colour1Field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(canChange)
        colourInput(inp)
      colour2Field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(isGradient)
        colourInput(inp2)
      easeTypeField = buildHtml tdiv(style = "display: flex".toCss):
        select:
          for e in EasingType:
            option: text $e
          proc onInput(e: Event; n: VNode) =
            easingType = e.target.OptionElement.selectedIndex.EasingType
    buildHtml tdiv:
      prop "Colour", colour1Field, canChange
      if canChange:
        prop "Grad. Colour 2", colour2Field, isGradient
        if isGradient:
          prop "Grad. ease", easeTypeField, isGradient

  template nameChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: string = "Shape %i%"
    once: appliers.add proc(i: int; fx: MapFixture) =
      if canChange:
        fx.n = inp.replace("%i%", $i).cstring
    buildHtml:
      let field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(canChange)
        bonkInput(inp, s => s, nil, s => s)
      prop "Name", field, canChange

  template rotateAndScale: untyped =
    var
      point {.global.} = [0.0, 0.0].MapPosition
      degrees {.global.} = 0.0
      scale {.global.} = 1.0
    once: appliers.add proc(i: int; fx: MapFixture) =
      template sh: untyped = fx.fxShape
      var p = sh.c
      p.x -= point.x
      p.y -= point.y
      if degrees != 0.0:
        p = rotatePoint(p, degrees.degToRad)
      sh.a += degrees.degToRad
      p.x *= scale
      p.y *= scale
      p.x += point.x
      p.y += point.y
      sh.c = p
      case sh.shapeType
      of stypeBx:
        sh.bxW *= scale
        sh.bxH *= scale
      of stypeCi:
        sh.ciR *= scale
      of stypePo:
        sh.poS *= scale
    buildHtml tdiv:
      let pointInput = buildHtml tdiv:
        bonkInput(point[0], prsFLimited, nil, niceFormatFloat)
        bonkInput(point[1], prsFLimited, nil, niceFormatFloat)
      prop "Rotate by", bonkInput(degrees, prsFLimited, nil, niceFormatFloat),
        degrees != 0.0
      prop "Scale by", bonkInput(scale, prsFLimited, nil, niceFormatFloat),
        scale != 1.0
      prop "Around point", pointInput, false

  nameChanger()
  floatProp("x", fx.fxShape.c.x)
  floatProp("y", fx.fxShape.c.y)
  block:
    let
      d2r = proc(f: float): float = degToRad(f)
      r2d = proc(f: float): float = radToDeg(f)
    floatProp("Angle", fx.fxShape.a, d2r, r2d)
  floatProp("Rect. width", fx.fxShape.bxW)
  floatProp("Rect. height", fx.fxShape.bxH)
  floatProp("Circle radius", fx.fxShape.ciR)
  floatProp("Poly. scale", fx.fxShape.poS)
  floatProp("Density", fx.de)
  floatProp("Bounciness", fx.re)
  floatProp("Friction", fx.fr)

  boolProp("No physics", fx.np)
  boolProp("No grapple", fx.ng)
  boolProp("Inner grapple", fx.ig)
  boolProp("Death", fx.d)
  boolProp("Shrink", fx.fxShape.sk)

  colourChanger()
  rotateAndScale()

  bonkButton "Apply", proc =
    removeDeletedFixtures()
    for i, f in selectedFixtures:
      for a in appliers: a(i, f)
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)


proc shapeMultiSelectCopy: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  var
    copyShapes {.global.}: seq[tuple[fx: MapFixture; sh: MapShape;
        cz: Option[MapCapZone]]]
    pasteAmount {.global.} = 1
  bonkButton "Copy shapes", proc =
    removeDeletedFixtures()
    copyShapes = @[]
    for fx in selectedFixtures:
      let fxId = moph.fixtures.find(fx)
      var copiedCz = none MapCapZone
      for cz in mapObject.capZones:
        if cz.i == fxId:
          copiedCz = some cz.copyObject()
          break
      copyShapes.add (
        fx: fx.copyObject(),
        sh: fx.fxShape.copyObject(),
        cz: copiedCz
      )

  prop "Paste amount", bonkInput(pasteAmount, parseInt, nil, i => $i)
  bonkButton "Paste shapes", proc =
    shapeMultiSelectSwitchPlatform()
    block outer:
      for _ in 1..pasteAmount:
        for (fx, sh, cz) in copyShapes.mitems:
          if fixturesBody.fx.len > 100:
            break outer
          moph.shapes.add sh.copyObject()
          let newFx = fx.copyObject()
          moph.fixtures.add newFx
          newFx.sh = moph.shapes.high
          selectedFixtures.add newFx
          fixturesBody.fx.add moph.fixtures.high
          if cz.isSome:
            let newCz = cz.get.copyObject()
            newCz.i = moph.fixtures.high
            mapObject.capZones.add newCz
    saveToUndoHistory()
    updateRenderer(true)
    updateRightBoxBody(-1)
    updateLeftBox()

proc shapeMultiSelectSelectAll: VNode = buildHtml tdiv:
  bonkButton "Select all", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = collect(newSeq):
      for fxId in fixturesBody.fx: fxId.getFx
    shapeMultiSelectElementBorders()
  bonkButton "Deselect all", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = @[]
    shapeMultiSelectElementBorders()
  bonkButton "Invert selection", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = collect(newSeq):
      for fxId in fixturesBody.fx:
        let fx = fxId.getFx
        if fx notin selectedFixtures:
          fx
    shapeMultiSelectElementBorders()
  bonkButton "Reverse selection order", proc =
    selectedFixtures.reverse()
    shapeMultiSelectElementBorders()

  var searchString {.global.} = ""
  bonkInput(searchString, s => s, nil, s => s)
  bonkButton "Select names starting with", proc =
    shapeMultiSelectSwitchPlatform()
    selectedFixtures = collect(newSeq):
      for fxId in fixturesBody.fx:
        let fx = fxId.getFx
        if fx.n.`$`.startsWith(searchString):
          fx
    shapeMultiSelectElementBorders()

proc shapeMultiSelectDelete: VNode =
  buildHtml bonkButton "Delete shapes", proc =
    for f in selectedFixtures:
      let fxId = moph.fixtures.find f
      if fxId == -1: continue
      deleteFx(fxId)
    saveToUndoHistory()
    selectedFixtures = @[]
    updateRenderer(true)
    updateRightBoxBody(-1)

proc shapeMultiSelectMove: VNode = buildHtml tdiv(style =
  "display: flex; flex-flow: row wrap; justify-content: space-between;".toCss
    ):
  text "Move"
  template fx: untyped = fixturesBody.fx
  proc update =
    updateRightBoxBody(-1)
    updateRenderer(true)
    saveToUndoHistory()
  proc getSelectedFxIds: seq[int] =
    selectedFixtures.mapIt moph.fixtures.find(it)
  bonkButton "Down", proc =
    let selectedFxIds = getSelectedFxIds()
    for i in countup(1, fx.high):
      if fx[i] in selectedFxIds and
          fx[i - 1] notin selectedFxIds:
        swap(fx[i], fx[i - 1])
    update()
  bonkButton "Up", proc =
    let selectedFxIds = getSelectedFxIds()
    for i in countdown(fx.high - 1, 0):
      if fx[i] in selectedFxIds and
          fx[i + 1] notin selectedFxIds:
        swap(fx[i], fx[i + 1])
    update()
  bonkButton "Bottom", proc =
    let selectedFxIds = getSelectedFxIds()
    var moveIndex = 0
    for i in countup(0, fx.high):
      if fx[i] notin selectedFxIds: continue
      inc moveIndex
      for j in countdown(i, moveIndex):
        swap fx[j], fx[j - 1]
    update()
  bonkButton "Top", proc =
    let selectedFxIds = getSelectedFxIds()
    var moveIndex = fx.high
    for i in countdown(fx.high, 0):
      if fx[i] notin selectedFxIds: continue
      dec moveIndex
      for j in countup(i, moveIndex):
        swap fx[j], fx[j + 1]
    update()
  bonkButton "Reverse", proc =
    var selectedFxIds = getSelectedFxIds()
    let fxIdPositions = collect(newSeq):
      for i, fxId in fx:
        let si = selectedFxIds.find fxId
        if si == -1: continue
        selectedFxIds.del si
        i
    for i in 0..fxIdPositions.len div 2 - 1:
      swap fx[fxIdPositions[i]],
           fx[fxIdPositions[fxIdPositions.high - i]]
    update()

proc shapeMultiSelect*: VNode =
  shapeMultiSelectSwitchPlatform()
  buildHtml(tdiv(
      style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
    shapeMultiSelectSelectAll()
    shapeMultiSelectEdit()
    shapeMultiSelectMove()
    shapeMultiSelectDelete()
    shapeMultiSelectCopy()
