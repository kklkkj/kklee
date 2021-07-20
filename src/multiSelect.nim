import sugar, strutils, algorithm, sequtils, strformat
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import mathexpr
import kkleeApi, bonkElements

let theEvaluator = newEvaluator()

var selectedFixtures*: seq[MapFixture]

type boolPropValue = enum
  bpSame, bpTrue, bpFalse

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

proc shapeMultiSelect*: VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    tdiv(style = "font-size:12px".toCss):
      text "Shift+click shape name fields to select shapes"
    tdiv(style = "font-size:12px".toCss):
      text "Variables: x is current value, i is index in list of selected shapes"
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

    bonkButton "Apply", proc =
      for i, b in selectedFixtures.mpairs:
        for a in appliers: a(i, b)
      saveToUndoHistory()
      updateRenderer(true)
