import dom, strutils, math, sugar, strformat
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

type
  ShapeGeneratorKind = enum
    sgsEllipse = "Ellipse/Spiral"
  ShapeGeneratorState = ref object
    case kind*: ShapeGeneratorKind
    of sgsEllipse:
      ewr*, ehr*, eaStart*, eaEnd*, eAngle*, ex*, ey*, espiralStart*,
        eheight*: float
      ehollow*: bool
      eprec*: int
      ecolour*: int

var
  gs: ShapeGeneratorState = ShapeGeneratorState(kind: sgsEllipse)
  nShapes: int

proc generateEllipse(body: MapBody): int =
  if gs.ehollow:
    proc getPos(a: float; s: float): MapPosition =
      var r = [gs.ewr * sin(a) * s, gs.ehr * cos(a) * s]
      let sa = gs.eAngle
      result = [
        r.x * cos(sa) - r.y * sin(sa) + gs.ex,
        r.x * sin(sa) + r.y * cos(sa) + gs.ey
      ]

    let ad = (gs.eaEnd - gs.eaStart) / gs.eprec.float

    for n in 0..gs.eprec-1:
      let
        a = gs.eaEnd - ad * n.float
        spiralMul = gs.espiralStart + (1 - gs.espiralStart) * (n / gs.eprec)
        spiralMul2 = gs.espiralStart + (1 - gs.espiralStart) *
          ((n + 1) / gs.eprec)
        p1 = getPos(a, spiralMul)
        p2 = getPos(a - ad, spiralMul2)

      let shape = MapShape(
        stype: "bx",
        c: [(p1.x + p2.x) / 2, (p1.y + p2.y) / 2].MapPosition,
        bxH: gs.eheight,
        bxW: sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2),
        a: arctan((p1.y - p2.y) / (p1.x - p2.x))
      )
      moph.shapes.add shape

      let fixture = MapFixture(n: &"hollowEllipse{n}", de: NaN, re: NaN,
        fr: NaN, f: gs.ecolour, sh: moph.shapes.high
      )
      moph.fixtures.add fixture
      body.fx.add moph.fixtures.high

    result = gs.eprec

  else:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: gs.eAngle,
      c: [gs.ex, gs.ey].MapPosition
    )

    for n in 0..gs.eprec:
      let a = gs.eaEnd - (gs.eaEnd - gs.eaStart) / gs.eprec.float * n.float
      shape.poV.add [
        sin(a) * gs.ewr, cos(a) * gs.ehr
      ].MapPosition

    moph.shapes.add shape
    let fixture = MapFixture(n: "ellipse", de: NaN, re: NaN, fr: NaN,
        f: gs.ecolour, sh: moph.shapes.high
    )
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high
    result = 1

  updateRenderer(true)
  updateRightBoxBody(-1)

proc setGs(kind: ShapeGeneratorKind) =
  case kind
  of sgsEllipse:
    gs = ShapeGeneratorState(
      kind: sgsEllipse,
      ewr: 100.0, ehr: 100.0, eaStart: 0.0, eaEnd: 2 * PI, eAngle: 0.0,
      ex: 0.0, ey: 0.0, ehollow: false, eprec: 16, espiralStart: 1.0,
      eheight: 1.0, ecolour: 0xffffff
    )

setGs sgsEllipse

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    select:
      for s in ShapeGeneratorKind:
        option: text $s
      proc onInput(e: Event; n: VNode) =
        setGs e.target.OptionElement.selectedIndex.ShapeGeneratorKind

    let
      generateProc =
        case gs.kind
        of sgsEllipse: generateEllipse
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
    template pbiAngle(va): untyped =
      var angle = (va * 180 / PI).round(3)
      bonkInput(angle, prsFLimited, proc =
        va = (angle * PI / 180)
        update()
      , niceFormatFloat)

    let fcss =
      "display:flex; flex-flow: row wrap; justify-content: space-between".toCss

    case gs.kind:
    of sgsEllipse:
      tdiv(style = fcss):
        text "x"
        pbi gs.ex
      tdiv(style = fcss):
        text "y"
        pbi gs.ey
      tdiv(style = fcss):
        text "Angle"
        pbiAngle gs.eAngle
      tdiv(style = fcss):
        text "Colour"
        bonkInput(gs.ecolour, parseHexInt, update, i => i.toHex(6))

      tdiv(style = fcss):
        text "Width radius"
        pbi gs.ewr
      tdiv(style = fcss):
        text "Height radius"
        pbi gs.ehr
      tdiv(style = fcss):
        text "Angle start"
        pbiAngle gs.eaStart
      tdiv(style = fcss):
        text "Angle end"
        pbiAngle gs.eaEnd

      tdiv(style = fcss):
        text "Hollow"
        input(`type` = "checkbox", checked = $gs.ehollow):
          proc onChange(e: Event; n: VNode) =
            gs.ehollow = e.target.Element.checked
            update()
      if gs.ehollow:
        tdiv(style = fcss):
          text "Rect height"
          bonkInput(gs.eheight, prsFLimitedPositive, update, niceFormatFloat)
        tdiv(style = fcss):
          text "Spiral start"
          pbi gs.espiralStart


      tdiv(style = fcss):
        text "Shapes/verticies"
        bonkInput(gs.eprec, proc(s: string): int =
          result = s.parseInt
          if result notin 1..99: raise newException(ValueError, "")
        , update, i => $i)

    bonkButton("Apply", proc =
      update()
      nShapes = 0
      saveToUndoHistory()
    )

    proc onMouseEnter = update()
    proc onMouseLeave = remove()


