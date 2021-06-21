import dom, strutils, math, sugar, strformat
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

type
  ShapeGeneratorKind = enum
    sgsEllipse = "Ellipse/Spiral", sgsSine = "Sine wave"
  ShapeGeneratorState = ref object
    x*, y*, angle*: float
    colour*: int
    prec*: int
    case kind*: ShapeGeneratorKind
    of sgsEllipse:
      ewr*, ehr*, eaStart*, eaEnd*, espiralStart*: float
      ehollow*: bool
    of sgsSine:
      swidth*, sheight*, sosc*, sstart*: float

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
      fr: NaN, f: gs.colour, sh: moph.shapes.high
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
        f: gs.colour, sh: moph.shapes.high
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

# >:(

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    # select(value = $gs.kind):
    #   for s in ShapeGeneratorKind:
    #     option(value = $s): text $s
    #   proc onInput(e: Event; n: VNode) =
    #     setGs e.target.OptionElement.selectedIndex.ShapeGeneratorKind

    let
      generateProc =
        case gs.kind
        of sgsEllipse: generateEllipse
        of sgsSine: generateSine
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

    let fcss =
      "display:flex; flex-flow: row wrap; justify-content: space-between".toCss

    if selecting:
      template sb(s): untyped =
        bonkButton($s, proc =
          setGs s
          selecting = false
        )
      sb sgsEllipse
      sb sgsSine

    else:
      bonkButton("Back", proc =
        selecting = true
        remove()
      )

      tdiv(style = fcss):
        text "x"
        pbi gs.x
      tdiv(style = fcss):
        text "y"
        pbi gs.y
      tdiv(style = fcss):
        text "Angle"
        pbi gs.angle
      tdiv(style = fcss):
        text "Colour"
        bonkInput(gs.colour, parseHexInt, update, i => i.toHex(6))
      tdiv(style = fcss):
        text "Shapes/verticies"
        bonkInput(gs.prec, proc(s: string): int =
          result = s.parseInt
          if result notin 1..99: raise newException(ValueError, "")
        , update, i => $i)

      case gs.kind:
      of sgsEllipse:
        tdiv(style = fcss):
          text "Width radius"
          pbi gs.ewr
        tdiv(style = fcss):
          text "Height radius"
          pbi gs.ehr
        tdiv(style = fcss):
          text "Angle start"
          pbi gs.eaStart
        tdiv(style = fcss):
          text "Angle end"
          pbi gs.eaEnd

        tdiv(style = fcss):
          text "Hollow"
          input(`type` = "checkbox", checked = $gs.ehollow):
            proc onChange(e: Event; n: VNode) =
              gs.ehollow = e.target.Element.checked
              update()
        if gs.ehollow:
          tdiv(style = fcss):
            text "Spiral start"
            pbi gs.espiralStart

      of sgsSine:
        tdiv(style = fcss):
          text "Width"
          pbi gs.swidth
        tdiv(style = fcss):
          text "Height"
          pbi gs.sheight
        tdiv(style = fcss):
          text "Oscillations"
          pbi gs.sosc

      bonkButton(&"Save {$gs.kind}", proc =
        update()
        nShapes = 0
        saveToUndoHistory()
      )

      proc onMouseEnter = update()
      proc onMouseLeave = remove()


