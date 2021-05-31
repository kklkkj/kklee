import dom, strutils, math, sugar
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

type
  ShapeGeneratorShapeKind = enum
    sgsEllipse
  ShapeGeneratorShapeState = ref object
    case kind*: ShapeGeneratorShapeKind
    of sgsEllipse:
      ewr*, ehr*, eaStart*, eaEnd*: float
      ehollow*: bool
      eprec*: int

var gs: ShapeGeneratorShapeState = ShapeGeneratorShapeState(kind: sgsEllipse)

proc generateEllipse(body: MapBody) =
  if gs.ehollow:
    discard
  else:
    let shape = MapShape(stype: "po", poS: 1.0)

    var n = gs.eaStart
    while n < gs.eaEnd:
      shape.poV.add [
        sin(n) * gs.ewr, cos(n) * gs.ehr
      ].MapPosition
      n += (gs.eaEnd - gs.eaStart) / gs.eprec.float

    moph.shapes.add shape
    let fixture = MapFixture(de: NaN, re: NaN, fr: NaN, f: 0xffffff,
        sh: moph.shapes.high)
    moph.fixtures.add fixture
    body.fx.add moph.fixtures.high

  updateRenderer(true)
  updateRightBoxBody(-1)


proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; column-gap: 5px; flex-flow: column".toCss)):
    let updateProc = proc =
      discard

    template pbi(va): untyped = bonkInput(va, parseFloat, proc =
      updateProc()
    )
    case gs.kind:
    of sgsEllipse:
      text "Width radius"
      pbi gs.ewr
      text "Height radius"
      pbi gs.ehr
      text "Angle start"
      pbi gs.eaStart
      text "Angle end"
      pbi gs.eaEnd
      text "Hollow"
      input(`type` = "checkbox", checked = $gs.ehollow):
        proc onChange(e: Event; n: VNode) =
          gs.ehollow = e.target.Element.checked
          updateProc()
      text "Number of shapes"
      bonkInput(gs.eprec,
      proc(s: string): int =
        result = s.parseInt
        if result notin 0..99: raise newException(ValueError, "")
      , proc = updateProc())

      bonkButton("Generate", () => generateEllipse(body))


