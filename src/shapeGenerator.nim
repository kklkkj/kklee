import dom, strutils, math, sugar, strformat
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

type
  ShapeGeneratorKind = enum
    sgsEllipse = "Ellipse/Spiral", sgsSine = "Sine wave",
    sgsLinearGradient = "Linear gradient",
    sgsRadialGradient = "Radial gradient"
  ShapeGeneratorState = ref object
    x*, y*, angle*: float
    colour*: int
    prec*: int
    kind*: ShapeGeneratorKind
    noPhysics*: bool

    # Ellipse
    ewr*, ehr*, eaStart*, eaEnd*, espiralStart*: float
    ehollow*: bool

    # Sine wave
    swidth*, sheight*, sosc*, sstart*: float

    # Gradients
    colour2*: int

    gwidth*, gheight*: float
    grad1*, grad2*: float



var
  gs: ShapeGeneratorState = ShapeGeneratorState(kind: sgsEllipse)
  nShapes: int
  selecting: bool = true


proc dtr(f: float): float = f.degToRad

proc genLinesShape(body: MapBody; getPos: float -> MapPosition) =
  proc getPosAdj(x: float): MapPosition =
    let
      r = getPos(x)
      sa = gs.angle.dtr
    return [
      r.x * cos(sa) - r.y * sin(sa) + gs.x,
      r.x * sin(sa) + r.y * cos(sa) + gs.y
    ]

  for n in 0..gs.prec-1:
    let
      p1 = getPosAdj(n / gs.prec)
      p2 = getPosAdj((n + 1) / gs.prec)

    let shape = MapShape(
      stype: "bx",
      c: [(p1.x + p2.x) / 2, (p1.y + p2.y) / 2].MapPosition,
      bxH: 1,
      bxW: sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2),
      a: arctan((p1.y - p2.y) / (p1.x - p2.x))
    )
    moph.shapes.add shape

    let fixture = MapFixture(n: &"rect{n}", de: NaN, re: NaN,
      fr: NaN, f: gs.colour, sh: moph.shapes.high, np: gs.noPhysics
    )
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high


proc generateEllipse(body: MapBody): int =
  if gs.ehollow:
    proc getPos(x: float): MapPosition =
      let
        a = gs.eaEnd.dtr - (gs.eaEnd.dtr - gs.eaStart.dtr) * x
        s = gs.espiralStart + (1 - gs.espiralStart) * x
      return [gs.ewr * sin(a) * s, gs.ehr * cos(a) * s]

    genLinesShape(body, getPos)

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

    moph.shapes.add shape
    let fixture = MapFixture(n: "ellipse", de: NaN, re: NaN, fr: NaN,
        f: gs.colour, sh: moph.shapes.high, np: gs.noPhysics
    )
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high
    result = 1

  updateRenderer(true)
  updateRightBoxBody(-1)

proc generateSine(body: MapBody): int =
  proc getPos(x: float): MapPosition =
    let
      sx = x * 2 * PI * gs.sosc + gs.sstart
      asx = sx + sin(2 * sx) / 2.7
    return [gs.swidth * (asx - gs.sstart) / gs.sosc / 2 / PI,
      sin(asx) * gs.sheight]

  genLinesShape(body, getPos)

  result = gs.prec

proc getGradientColourAt(colour1, colour2: int; pos: float): int =
  proc getRGB(colour: int): array[3, int] =
    [colour shr 16 and 255, colour shr 8 and 255, colour and 255]
  let
    colour1 = getRGB(colour1)
    colour2 = getRGB(colour2)
  var rc: array[3, int]
  for i in 0..2:
    rc[i] =
      int(colour1[i].float * (1.0 - pos) +
          colour2[i].float * pos)
  return rc[0] shl 16 or rc[1] shl 8 or rc[2]


proc generateGradient(body: MapBody): int =
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
        var r = shape.c
        shape.c = [
          r.x * cos(sa) - r.y * sin(sa) + gs.x,
          r.x * sin(sa) + r.y * cos(sa) + gs.y
        ]
    of sgsRadialGradient:
      let crm = i.float / (gs.prec.float - 1)
      shape = MapShape(
        stype: "ci", ciR: gs.grad1 * crm + gs.grad2 * (1.0 - crm),
        c: [gs.x, gs.y]
      )
    else: raise CatchableError.newException("gs.kind not gradient")

    moph.shapes.add shape
    let
      colour = getGradientColourAt(gs.colour, gs.colour2, i / gs.prec)
      fixture = MapFixture(n: &"gradient{i}", de: NaN, re: NaN,
        fr: NaN, f: colour, sh: moph.shapes.high, np: gs.noPhysics)
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high
  return gs.prec


proc setGs(kind: ShapeGeneratorKind) =
  case kind
  of sgsEllipse:
    gs = ShapeGeneratorState(
      kind: sgsEllipse,
      ewr: 100.0, ehr: 100.0, eaStart: 0.0, eaEnd: 360, angle: 0.0,
      x: 0.0, y: 0.0, ehollow: false, prec: 16, espiralStart: 1.0,
      colour: 0xffffff
    )
  of sgsSine:
    gs = ShapeGeneratorState(
      kind: sgsSine,
      swidth: 300, sheight: 75, sosc: 2, x: 0.0, y: 0.0, angle: 0.0,
      sstart: 0.0, colour: 0xffffff, prec: 30
    )
  of sgsLinearGradient:
    gs = ShapeGeneratorState(
      kind: sgsLinearGradient, x: 0.0, y: 0.0, angle: 0.0, prec: 12,
      gwidth: 200.0, gheight: 150.0, colour: 0xff0000, colour2: 0x0000ff,
      noPhysics: true
    )
  of sgsRadialGradient:
    gs = ShapeGeneratorState(
      kind: sgsRadialGradient, x: 0.0, y: 0.0, angle: 0.0, prec: 12,
      grad1: 30.0, grad2: 150.0, colour: 0xff0000, colour2: 0x0000ff,
      noPhysics: true
    )

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    let
      generateProc =
        case gs.kind
        of sgsEllipse: generateEllipse
        of sgsSine: generateSine
        of sgsLinearGradient, sgsRadialGradient: generateGradient
      generate = proc =
        nShapes = generateProc(body)
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
    template prop(name: string; field: untyped): untyped =
      buildHtml: tdiv(style =
        "display:flex; flex-flow: row wrap; justify-content: space-between"
        .toCss):
        text name
        field

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

    else:
      bonkButton("Back", proc =
        selecting = true
        remove()
      )

      let precInput =
        bonkInput(gs.prec, proc(s: string): int =
          result = s.parseInt
          if result notin 1..99: raise newException(ValueError, "")
        , update, i => $i)

      prop("No physics", checkbox(gs.noPhysics))

      case gs.kind
      of sgsEllipse:
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour", colourInput(gs.colour))
        prop("Angle", pbi gs.angle)
        prop("Shapes/verticies", precInput)
        prop("Width radius", pbi gs.ewr)
        prop("Height radius", pbi gs.ehr)
        prop("Angle start", pbi gs.eaStart)
        prop("Angle end", pbi gs.eaEnd)

        template hollowCheckbox: untyped =
          buildHtml:
            input(`type` = "checkbox", checked = $gs.ehollow):
              proc onChange(e: Event; n: VNode) =
                gs.ehollow = e.target.Element.checked
                update()
        prop("Hollow", checkbox(gs.ehollow))

        if gs.ehollow:
          prop("Spiral start", pbi gs.espiralStart)

      of sgsSine:
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour", colourInput(gs.colour))
        prop("Angle", pbi gs.angle)
        prop("Shapes", precInput)
        prop("Width", pbi gs.swidth)
        prop("Height", pbi gs.sheight)
        prop("Oscillations", pbi gs.sosc)
      of sgsLinearGradient:
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour 1", colourInput(gs.colour))
        prop("Colour 2", colourInput(gs.colour2))
        prop("Shapes", precInput)
        prop("Angle", pbi gs.angle)
        prop("Width", pbi gs.gwidth)
        prop("Height", pbi gs.gheight)
      of sgsRadialGradient:
        prop("x", pbi gs.x)
        prop("y", pbi gs.y)
        prop("Colour 1", colourInput(gs.colour))
        prop("Colour 2", colourInput(gs.colour2))
        prop("Shapes", precInput)
        prop("Inner circle radius", pbi gs.grad1)
        prop("Outer circle radius", pbi gs.grad2)



      bonkButton(&"Save {$gs.kind}", proc =
        update()
        nShapes = 0
        saveToUndoHistory()
      )

      proc onMouseEnter = update()
      proc onMouseLeave = remove()
