import dom, strutils, math, sugar
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

type
  ShapeGeneratorKind = enum
    sgsEllipse = "Ellipse/Spiral"
  ShapeGeneratorState = ref object
    case kind*: ShapeGeneratorKind
    of sgsEllipse:
      ewr*, ehr*, eaStart*, eaEnd*, eAngle*, ex*, ey*, espiralStart*: float
      ehollow*: bool
      eprec*: int
      ecolour*: int

var
  gs: ShapeGeneratorState = ShapeGeneratorState(kind: sgsEllipse)
  nShapes: int

proc generateEllipse(body: MapBody): int =
  if gs.ehollow:
    discard
  else:
    result = 1
    let shape = MapShape(
      stype: "po", poS: 1.0, a: gs.eAngle,
      c: [gs.ex, gs.ey].MapPosition
    )

    var n = gs.eaEnd
    while n > gs.eaStart:
      shape.poV.add [
        sin(n) * gs.ewr, cos(n) * gs.ehr
      ].MapPosition
      n -= (gs.eaEnd - gs.eaStart) / gs.eprec.float

    moph.shapes.add shape
    let fixture = MapFixture(n: "Generated shape", de: NaN, re: NaN, fr: NaN,
        f: gs.ecolour, sh: moph.shapes.high)
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high

  updateRenderer(true)
  updateRightBoxBody(-1)

proc setGs(kind: ShapeGeneratorKind) =
  case kind
  of sgsEllipse:
    gs = ShapeGeneratorState(
      kind: sgsEllipse,
      ewr: 100.0, ehr: 100.0, eaStart: 0.0, eaEnd: 2 * PI, eAngle: 0.0,
      ex: 0.0, ey: 0.0, ehollow: false, eprec: 16, espiralStart: 1.0,
      ecolour: 0xffffff
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


