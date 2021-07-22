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
    ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
      li text "Shift+click shape name fields to select shapes"
      li text """Note: you will have to reselect the platform to see changes
 made by multiselect"""
      li text """Variables: x is current value, i is index in list of
 selected shapes (the first shape you selected will have i=0, the next one
 i=1, i=2, etc)"""
      li text "Arithmetic, such as x*2+50, will be evaluated"

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
      for i, f in selectedFixtures.mpairs:
        for a in appliers: a(i, f)
      saveToUndoHistory()
      updateRenderer(true)
    bonkButton "Delete shapes", proc =
      for f in selectedFixtures:
        let fxid = moph.fixtures.find f
        if fxid == -1: continue
        deleteFx(fxid)
      saveToUndoHistory()
      selectedFixtures = @[]
      updateRenderer(true)
      updateRightBoxBody(-1)
