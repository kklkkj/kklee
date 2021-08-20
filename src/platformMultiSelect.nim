import
  std/[sugar, strutils, strformat, dom, math, options],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr,
  kkleeApi, bonkElements

var selectedBodies*: seq[MapBody]

proc removeDeletedBodies =
  var i = 0
  while i < selectedBodies.len:
    let b = selectedBodies[i]
    if moph.bodies.find(b) == -1:
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

proc platformMultiSelectEdit: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
    li text "Shift+click platform elements to select platforms"
    li text (
      "Variables: x is current value, i is index in list of selected " &
      "platforms (the first platform you selected will have i=0, the next one" &
      "i=1, i=2, etc)"
    )
    li text "Arithmetic, such as x*2+50, will be evaluated"

  var appliers {.global.}: seq[(int, MapBody) -> void]

  proc floatPropInput(inp: var string): VNode =
    buildHtml: bonkInput(inp, proc(parserInput: string): string =
      let evtor = newEvaluator()
      evtor.addVars {"x": 0.0, "i": 0.0}
      discard evtor.eval parserInput
      return parserInput
    , nil, s=>s)

  proc floatPropApplier(inp: string; i: int; prop: float): float =
    let evtor = newEvaluator()
    evtor.addVars {"x": prop, "i": i.float}
    result = evtor.eval(inp).clamp(-1e6, 1e6)
    if result.isNaN: result = 0

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
      mapBProp = inpToPropF floatPropApplier(inp, i, propToInpF mapBProp)

    buildHtml:
      prop name, floatPropInput(inp)

  template boolProp(name: string; mapBProp: untyped): untyped =
    var inp {.global.}: boolPropValue
    once: appliers.add proc(i: int; b {.inject.}: MapBody) =
      case inp
      of tfsFalse: mapBProp = false
      of tfsTrue: mapBProp = true
      of tfsSame: discard
    buildHtml:
      prop name, tfsCheckbox(inp)

  proc dropDownPropSelect[T](
    inp: var Option[T];
    options: seq[tuple[label: string; value: T]]
  ): VNode =
    let selectStyle = (if inp.isSome: "border: red solid 2px" else: "").toCss
    buildHtml:
      select(style = selectStyle):
        if inp.isNone:
          option(selected = ""): text "Unchanged"
        else:
          option: text "Unchanged"

        for o in options:
          let selected = inp.isSome and inp.get == o[1]
          if selected:
            option(selected = ""): text o[0]
          else:
            option: text o[0]

        proc onInput(e: Event; n: VNode) =
          let i = e.target.OptionElement.selectedIndex
          inp =
            if i == 0: none T.typedesc
            else: some options[i - 1][1]
  template dropDownProp[T](
    mapBProp: untyped;
    options: openArray[tuple[label: string; value: T]]
  ): untyped =
    var
      inp {.global.}: Option[T]
    once: appliers.add proc(i: int; b {.inject.}: MapBody) =
      if inp.isSome:
        mapBProp = inp.get
    dropDownPropSelect(inp, @options)


  template nameChanger: untyped =
    var
      canChange {.global.} = false
      inp {.global.}: string = "Platform %i%"
    once: appliers.add proc(i: int; b: MapBody) =
      if canChange:
        b.n = inp.replace("%i%", $i).cstring
    buildHtml tdiv(style = "display: flex".toCss):
      checkbox(canChange)
      bonkInput(inp, s => s, nil, s => s)

  prop "Type", dropDownProp(b.btype, [
    ("Stationary", $btStationary), ("Free moving", $btDynamic),
    ("Kinematic", $btKinematic)
  ])
  prop("Name", nameChanger())
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
  prop "Collision group", dropDownProp(b.f_c, [
    ("A", cg.A.int), ("B", cg.B.int), ("C", cg.C.int), ("D", cg.D.int)
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
  prop "Force direction", dropDownProp(b.cf.w, [
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

proc platformMultiSelect*: VNode = buildHtml(tdiv(
    style = "display: flex; flex-flow: column; row-gap: 10px".toCss)):
  platformMultiSelectSelectAll()
  platformMultiSelectEdit()
  platformMultiSelectDelete()
  # platformMultiSelectCopy()
