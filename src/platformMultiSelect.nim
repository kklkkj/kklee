import
  std/[sugar, strutils, algorithm, sequtils, dom, math, options],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

var selectedBodies*: seq[MapBody]

proc removeDeletedBodies =
  var i = 0
  while i < selectedBodies.len:
    let b = selectedBodies[i]
    if b notin moph.bodies:
      selectedBodies.delete i
    else:
      inc i

proc platformMultiSelectElementBorders * =
  removeDeletedBodies()
  let platformsContainer = docElemById("mapeditor_leftbox_platformtable")
  if platformsContainer.isNil: return
  let platformElements = platformsContainer.children[0].children

  for i, bodyElementParent in platformElements:
    let
      be = bodyElementParent.children[0]
      firstChild = be.children[0]
    if firstChild.class == "kkleeMultiSelectPlatformIndexLabel":
      firstChild.remove()

    let selectedId = selectedBodies.find(moph.bro[i].getBody)
    if selectedId == -1:
      be.style.border = ""
    else:
      be.style.border = "4px solid blue"

      let indexLabel = document.createElement("span")
      indexLabel.innerText = $selectedId
      indexLabel.setAttr("style", "color: blue; font-size: 12px")
      indexLabel.class = "kkleeMultiSelectPlatformIndexLabel"
      be.insertBefore(indexLabel, be.children[0])

proc platformMultiSelectDelete: VNode =
  buildHtml bonkButton "Delete platforms", proc =
    for b in selectedBodies:
      let bId = moph.bodies.find b
      if bId == -1: continue
      deleteBody bId
    saveToUndoHistory()
    selectedBodies = @[]
    updateRenderer(true)
    updateLeftBox()
    setCurrentBody(-1)
    updateRightBoxBody(-1)

proc platformMultiSelectSelectAll: VNode = buildHtml tdiv:
  bonkButton "Select all", proc =
    selectedBodies = collect(newSeq):
      for bId in moph.bro: bId.getBody
    platformMultiSelectElementBorders()
  bonkButton "Deselect all", proc =
    selectedBodies = @[]
    platformMultiSelectElementBorders()
  bonkButton "Invert selection", proc =
    selectedBodies = collect(newSeq):
      for bId in moph.bro:
        let b = bId.getBody
        if b notin selectedBodies:
          b
    platformMultiSelectElementBorders()
  bonkButton "Reverse selection order", proc =
    selectedBodies.reverse()
    platformMultiSelectElementBorders()

  var searchString {.global.} = ""
  bonkInput(searchString, s => s, nil, s => s)
  bonkButton "Select names starting with", proc =
    selectedBodies = collect(newSeq):
      for bId in moph.bro:
        let b = bId.getBody
        if b.n.`$`.startsWith(searchString):
          b
    platformMultiSelectElementBorders()

proc platformMultiSelectEdit: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):

  proc onMouseEnter =
    setEditorExplanation("""
[kklee]
Shift+click platform elements to select platforms
Variables:
 - x is the current value
 - i is the index in list of selected platforms (the first platform you selected will have i=0, the next one i=1, i=2, etc)
Arithmetic, such as x*2+50, will be evaluated
 - n is number of platforms selected
List of supported functions:
https://yardanico.github.io/nim-mathexpr/mathexpr.html#what-is-supportedqmark
Additional function: rand() - random number between 0 and 1
    """)

  var appliers {.global.}: seq[(int, MapBody) -> void]

  template floatProp(
    name: string; mapBProp: untyped;
    inpToProp = floatNop;
    propToInp = floatNop;
  ): untyped =
    let
      inpToPropF = inpToProp
      propToInpF = propToInp
    var inp {.global.}: string = "x"

    once: appliers.add proc (i: int; b {.inject.}: MapBody) =
      mapBProp = inpToPropF floatPropApplier(inp, i, selectedBodies.len,
          propToInpF mapBProp)

    buildHtml:
      prop name, floatPropInput(inp), inp != "x"

  template boolProp(name: string; mapBProp: untyped): untyped =
    var inp {.global.}: boolPropValue
    once: appliers.add proc(i: int; b {.inject.}: MapBody) =
      case inp
      of tfsFalse: mapBProp = false
      of tfsTrue: mapBProp = true
      of tfsSame: discard
    buildHtml:
      prop name, tfsCheckbox(inp), inp != tfsSame

  template dropDownProp[T](
    name: string;
    mapBProp: untyped;
    options: openArray[tuple[label: string; value: T]]
  ): untyped =
    var
      inp {.global.}: Option[T]
    once: appliers.add proc(i: int; b {.inject.}: MapBody) =
      if inp.isSome:
        mapBProp = inp.get
    buildHtml:
      prop name, dropDownPropSelect(inp, @options), inp.isSome


  template nameChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: string = "Platform %i%"
    once: appliers.add proc(i: int; b: MapBody) =
      if canChange:
        b.n = inp.replace("%i%", $i).cstring
    buildHtml:
      let field = buildHtml tdiv(style = "display: flex".toCss):
        checkbox(canChange)
        bonkInput(inp, s => s, nil, s => s)
      prop "Name", field, canChange

  dropDownProp("Type", b.btype, [
    ("Stationary", $btStationary), ("Free moving", $btDynamic),
    ("Kinematic", $btKinematic)
  ])
  nameChanger()
  floatProp("x", b.p.x)
  floatProp("y", b.p.y)
  block:
    let
      d2r = proc(f: float): float = degToRad(f)
      r2d = proc(f: float): float = radToDeg(f)
    floatProp("Angle", b.a, d2r, r2d)
  floatProp("Bounciness", b.re)
  floatProp("Density", b.de)
  floatProp("Friction", b.fric)
  boolProp("Fric players", b.fricp)
  boolProp("Anti-tunnel", b.bu)
  type cg = MapBodyCollideGroup
  dropDownProp("Col. group", b.f_c, [
    ("A", cg.A), ("B", cg.B), ("C", cg.C), ("D", cg.D)
  ])
  boolProp("Col. players", b.f_p)
  boolProp("Col. A", b.f_1)
  boolProp("Col. B", b.f_2)
  boolProp("Col. C", b.f_3)
  boolProp("Col. D", b.f_4)
  floatProp("Start speed x", b.lv.x)
  floatProp("Start speed y", b.lv.y)
  floatProp("Start spin", b.av)
  floatProp("Linear drag", b.ld)
  floatProp("Spin drag", b.ad)
  boolProp("Fixed rotation", b.fr)
  floatProp("Apply x force", b.cf.x)
  floatProp("Apply y force", b.cf.y)
  dropDownProp("Force dir.", b.cf.w, [
    ("Absolute", true), ("Relative", false)
  ])
  floatProp("Apply torque", b.cf.ct)

  bonkButton "Apply", proc =
    removeDeletedBodies()
    for i, b in selectedBodies:
      for a in appliers: a(i, b)
    saveToUndoHistory()
    updateRenderer(true)
    updateLeftBox()
    updateRightBoxBody(-1)

proc platformMultiSelectMove: VNode = buildHtml tdiv(style =
  "display: flex; flex-flow: row wrap; justify-content: space-between;".toCss
    ):
  text "Move"
  template bro: untyped = moph.bro
  proc update =
    updateLeftBox()
    updateRenderer(true)
    saveToUndoHistory()
  proc getSelectedBIds: seq[int] =
    selectedBodies.mapIt moph.bodies.find(it)
  bonkButton "Down", proc =
    let selectedBIds = getSelectedBIds()
    for i in countdown(bro.high - 1, 0):
      if bro[i] in selectedBIds and
          bro[i + 1] notin selectedBIds:
        swap(bro[i], bro[i + 1])
    update()
  bonkButton "Up", proc =
    let selectedBIds = getSelectedBIds()
    for i in countup(1, bro.high):
      if bro[i] in selectedBIds and
          bro[i - 1] notin selectedBIds:
        swap(bro[i], bro[i - 1])
    update()
  bonkButton "Bottom", proc =
    let selectedBIds = getSelectedBIds()
    var moveIndex = bro.high
    for i in countdown(bro.high, 0):
      if bro[i] notin selectedBIds: continue
      dec moveIndex
      for j in countup(i, moveIndex):
        swap bro[j], bro[j + 1]
    update()
  bonkButton "Top", proc =
    let selectedBIds = getSelectedBIds()
    var moveIndex = 0
    for i in countup(0, bro.high):
      if bro[i] notin selectedBIds: continue
      inc moveIndex
      for j in countdown(i, moveIndex):
        swap bro[j], bro[j - 1]
    update()

proc platformMultiSelect*: VNode = buildHtml(tdiv(
    style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
  platformMultiSelectSelectAll()
  platformMultiSelectEdit()
  platformMultiSelectMove()
  platformMultiSelectDelete()
  # platformMultiSelectCopy()
