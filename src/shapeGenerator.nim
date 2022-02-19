import
  std/[dom, strutils, math, sugar, strformat],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr,
  kkleeApi, bonkElements, shapeMultiSelect, colours

type
  ShapeGeneratorKind = enum
    sgsEllipse = "Polygon/Ellipse/Spiral", sgsSine = "Sine wave",
    sgsLinearGradient = "Linear gradient",
    sgsRadialGradient = "Radial gradient", sgsEquation = "Parametric equation"
  ShapeGeneratorState = ref object
    kind: ShapeGeneratorKind
    body: MapBody
    multiSelect: bool

    x, y, angle: float
    colour: int
    prec: int
    noPhysics: bool
    rectHeight: float

    # Ellipse
    ewr, ehr, eaStart, eaEnd, espiralStart: float
    ehollow: bool

    # Sine wave
    swidth, sheight, sosc, sstart: float

    # Gradients
    gwidth, gheight: float
    grad1, grad2: float
    gdata: MultiColourGradient

    # Parametric equation
    eqInpX, eqInpY: string

var
  gs = ShapeGeneratorState(
    kind: sgsEllipse,
    multiSelect: false,
    x: 0.0, y: 0.0, angle: 0.0,
    colour: 0xffffff,
    prec: 16,
    noPhysics: false,
    rectHeight: 1.0,

    ewr: 100.0, ehr: 100.0, eaStart: 0.0, eaEnd: 360.0, ehollow: false,
    espiralStart: 1.0,

    swidth: 300.0, sheight: 75.0, sosc: 2, sstart: 0.0,

    gwidth: 200.0, gheight: 150.0, grad1: 30.0, grad2: 150.0,
    gdata: defaultMultiColourGradient(),

    eqInpX: "(t-0.5)*100", eqInpY: "-((t*2-1)^2)*100"
  )
  nShapes: int
  selecting: bool = true

proc setGs(kind: ShapeGeneratorKind) =
  case kind
  of sgsEllipse:
    gs.kind = sgsEllipse
    gs.noPhysics = false
    gs.prec = 16
  of sgsSine:
    gs.kind = sgsSine
    gs.noPhysics = false
    gs.prec = 30
  of sgsLinearGradient:
    gs.kind = sgsLinearGradient
    gs.noPhysics = true
    gs.prec = 12
  of sgsRadialGradient:
    gs.kind = sgsRadialGradient
    gs.noPhysics = true
    gs.prec = 12
  of sgsEquation:
    gs.kind = sgsEquation
    gs.noPhysics = false
    gs.prec = 20

func dtr(f: float): float = f.degToRad

func safeFloat(n: float): float =
  if n.isNaN:
    0.0
  else:
    n.clamp(-1e6, 1e6)
func safePos(p: MapPosition): MapPosition =
  [p.x.safeFloat, p.y.safeFloat].MapPosition

proc genLinesShape(getPos: float -> MapPosition) =
  proc getPosAdj(x: float): MapPosition =
    let sa = gs.angle.dtr
    var r = getPos(x)
    r = r.rotatePoint(sa)
    r.x += gs.x
    r.y += gs.y
    return r

  for n in 0..gs.prec-1:
    let
      p1 = getPosAdj(n / gs.prec).safePos
      p2 = getPosAdj((n + 1) / gs.prec).safePos

    let shape = MapShape(
      stype: "bx",
      c: [(p1.x + p2.x) / 2, (p1.y + p2.y) / 2].MapPosition,
      bxH: gs.rectHeight,
      bxW: sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2),
      a: arctan((p1.y - p2.y) / (p1.x - p2.x)).safeFloat
    )
    moph.shapes.add shape

    let fixture = MapFixture(n: cstring &"rect{n}", de: jsNull, re: jsNull,
      fr: jsNull, f: gs.colour, sh: moph.shapes.high, np: gs.noPhysics
    )
    moph.fixtures.add fixture
    gs.body.fx.add moph.fixtures.high


proc generateEllipse: int =
  if gs.ehollow:
    proc getPos(x: float): MapPosition =
      let
        a = gs.eaEnd.dtr - (gs.eaEnd.dtr - gs.eaStart.dtr) * x
        s = gs.espiralStart + (1 - gs.espiralStart) * x
      return [gs.ewr * sin(a) * s, gs.ehr * cos(a) * s]

    genLinesShape(getPos)

    result = gs.prec

  else:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: gs.angle.dtr,
      c: [gs.x, gs.y].MapPosition
    )

    for n in 0..gs.prec:
      let a = gs.eaEnd.dtr - (gs.eaEnd.dtr - gs.eaStart.dtr) /
        gs.prec.float * n.float
      shape.poV.add [
        sin(a) * gs.ewr, cos(a) * gs.ehr
      ].MapPosition
    if abs(gs.eaEnd - gs.eaStart) == 360:
      shape.poV.delete shape.poV.high

    moph.shapes.add shape
    let fixture = MapFixture(n: "ellipse", de: jsNull, re: jsNull, fr: jsNull,
        f: gs.colour, sh: moph.shapes.high, np: gs.noPhysics
    )
    moph.fixtures.add fixture
    gs.body.fx.add moph.fixtures.high
    result = 1

  updateRenderer(true)
  updateRightBoxBody(-1)

proc generateSine: int =
  proc getPos(x: float): MapPosition =
    let
      sx = x * 2 * PI * gs.sosc + gs.sstart
      asx = sx + sin(2 * sx) / 2.7
    return [gs.swidth * (asx - gs.sstart) / gs.sosc / 2 / PI,
      sin(asx) * gs.sheight]

  genLinesShape(getPos)

  result = gs.prec

proc generateEquation: int =
  proc getPos(x: float): MapPosition =
    let ev = newEvaluator()
    ev.addVar("t", x)
    return [ev.eval gs.eqInpX, ev.eval gs.eqInpY]

  genLinesShape(getPos)

  result = gs.prec

proc generateGradient: int =
  for i in 0..gs.prec-1:
    var shape: MapShape

    case gs.kind
    of sgsLinearGradient:
      shape = MapShape(
        stype: "bx", bxW: gs.gwidth / gs.prec.float, bxH: gs.gheight,
        a: gs.angle.dtr,
        c: [gs.gwidth * i.float / gs.prec.float - gs.gwidth / 2.0 +
          gs.gwidth / gs.prec.float / 2, 0].MapPosition
        )

      block:
        let sa = gs.angle.dtr
        shape.c = shape.c.rotatePoint(sa)
        shape.c.x += gs.x
        shape.c.y += gs.y
    of sgsRadialGradient:
      let crm = i.float / (gs.prec.float - 1)
      shape = MapShape(
        stype: "ci", ciR: gs.grad1 * crm + gs.grad2 * (1.0 - crm),
        c: [gs.x, gs.y]
      )
    else: raise CatchableError.newException("gs.kind not gradient")

    moph.shapes.add shape
    let
      colour = getColourAt(gs.gdata, GradientPos(i / (gs.prec - 1))).int
      fixture = MapFixture(n: cstring &"gradient{i}", de: jsNull, re: jsNull,
        fr: jsNull, f: colour, sh: moph.shapes.high, np: gs.noPhysics)
    moph.fixtures.add fixture
    gs.body.fx.add moph.fixtures.high
  return gs.prec

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    tdiv(style = "font-size:12px".toCss):
      text &"Shapes in platform: {body.fx.len}/100"
    var generateProc: void -> int
    if body != gs.body:
      selecting = true
    gs.body = body
    let
      generate = proc =
        nShapes = generateProc()
        updateRenderer(true)
        updateRightBoxBody(-1)
      remove = proc =
        body.fx.setLen body.fx.len - nShapes
        moph.fixtures.setLen moph.fixtures.len - nShapes
        moph.shapes.setLen moph.shapes.len - nShapes
        nShapes = 0
        updateRenderer(true)
        updateRightBoxBody(-1)
      update = proc =
        remove()
        generate()

    template pbi(va): untyped =
      bonkInput(va, prsFLimited, update, niceFormatFloat)

    if selecting:
      template sb(s): untyped =
        bonkButton($s, proc =
          setGs s
          selecting = false
        )
      sb sgsEllipse
      sb sgsSine
      sb sgsLinearGradient
      sb sgsRadialGradient
      sb sgsEquation

    else:
      bonkButton("Back", proc =
        selecting = true
        remove()
      )

      let precInput =
        bonkInput(gs.prec, proc(s: string): int =
          result = s.parseInt
          if result notin 1..999:
            raise newException(ValueError, "prec notin 1.999")
        , update, i => $i)

      prop("No physics", checkbox(gs.noPhysics))
      prop("Multi-select", checkbox(gs.multiSelect))

      case gs.kind
      of sgsEllipse:
        generateProc = generateEllipse
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour", colourInput(gs.colour))
        prop("Angle", pbi gs.angle)
        prop("Shapes/vertices", precInput)
        prop("Width radius", pbi gs.ewr)
        prop("Height radius", pbi gs.ehr)
        prop("Angle start", pbi gs.eaStart)
        prop("Angle end", pbi gs.eaEnd)
        prop("Hollow", checkbox(gs.ehollow))

        if gs.ehollow:
          prop("Spiral start", pbi gs.espiralStart)
          prop("Rect height", pbi gs.rectHeight)

      of sgsSine:
        generateProc = generateSine
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour", colourInput(gs.colour))
        prop("Angle", pbi gs.angle)
        prop("Shapes", precInput)
        prop("Width", pbi gs.swidth)
        prop("Height", pbi gs.sheight)
        prop("Oscillations", pbi gs.sosc)
        prop("Rect height", pbi gs.rectHeight)
      of sgsLinearGradient, sgsRadialGradient:
        generateProc = generateGradient
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        gradientProp(gs.gdata)
        prop("Shapes", precInput)
        case gs.kind
        of sgsLinearGradient:
          prop("Angle", pbi gs.angle)
          prop("Width", pbi gs.gwidth)
          prop("Height", pbi gs.gheight)
        of sgsRadialGradient:
          prop("Inner circle radius", pbi gs.grad1)
          prop("Outer circle radius", pbi gs.grad2)
        else: discard

      of sgsEquation:
        generateProc = generateEquation
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour", colourInput(gs.colour))
        prop("Angle", pbi gs.angle)
        prop("Shapes", precInput)
        prop("Rect height", pbi gs.rectHeight)

        # bonkInput but with a width of 150px
        proc bonkInputWide[T](variable: var T; parser: string -> T;
            afterInput: proc(): void = nil; stringify: T ->
                string): VNode =
          buildHtml:
            input(class =
              "mapeditor_field mapeditor_field_spacing_bodge fieldShadow",
              value = cstring variable.stringify, style = "width: 150px".toCss
            ):
              proc onInput(e: Event; n: VNode) =
                try:
                  variable = parser $n.value
                  e.target.style.color = ""
                  if not afterInput.isNil:
                    afterInput()
                except CatchableError:
                  e.target.style.color = "var(--kkleeErrorColour)"
        template eqInp(va): untyped =
          bonkInputWide(va, proc(s: string): string =
            # Check for error
            let ev = newEvaluator()
            ev.addVar("t", 0.0)
            discard ev.eval s
            return s
          , update, s=>s)
        prop("X", eqInp(gs.eqInpX))
        prop("Y", eqInp(gs.eqInpY))

        ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
          li text (
            "It is recommended that you experiment with equations on " &
            "something like Desmos before adding them here")


      bonkButton(&"Save {$gs.kind}", proc =
        update()
        if gs.multiSelect:
          shapeMultiSelectSwitchPlatform()
          for fxId in moph.fixtures.len-nShapes..moph.fixtures.high:
            selectedFixtures.add fxId.getFx
          shapeMultiSelectElementBorders()
        nShapes = 0
        saveToUndoHistory()
      )

      proc onMouseEnter = update()
      proc onMouseLeave = remove()
