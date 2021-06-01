import strformat, dom, sugar, strutils, options, math
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements


var
  markerFxi: Option[int]
  b: MapBody
  fx: MapFixture
  sh: MapShape

proc removeVertexMarker =
  if markerFxi.isNone: return
  let mfxi = markerFxi.get
  for i, j in b.fx:
    if j == mfxi:
      b.fx.delete i
      break
  moph.shapes.delete mfxi.getFx.sh
  moph.fixtures.delete mfxi
  markerFxi = none int
  updateRenderer(true)

proc setVertexMarker(vi: int) =
  removeVertexMarker()
  let
    v = sh.poV[vi]
    # Only scaled marker positions
    smp: MapPosition = [
      v.x * sh.poS,
      v.y * sh.poS
    ]
    markerPos: MapPosition = [
      smp.x * cos(sh.poA) - smp.y * sin(sh.poA) + sh.c.x,
      smp.x * sin(sh.poA) + smp.y * cos(sh.poA) + sh.c.y
    ]
  moph.shapes.add MapShape(
    stype: "ci", ciR: 3.0, ciSk: false, c: markerPos
  )
  moph.fixtures.add MapFixture(
    n: "temp marker", np: true, f: 0xff0000,
    sh: moph.shapes.high
  )
  let fxi = moph.fixtures.high
  b.fx.add fxi
  markerFxi = some fxi
  updateRenderer(true)

proc vertexEditor*(veb: var MapBody; vefx: var MapFixture): VNode =
  b = veb
  fx = vefx
  sh = fx.fxShape
  proc vertex(i: int; v: var MapPosition; poV: var seq[MapPosition]): VNode =
    buildHtml tdiv(style = "display: flex; flex-flow: row wrap".toCss):
      span(style = "width: 40px".toCss):
        text &"{i}."
      template cbi(va): untyped = bonkInput(va, parseFloat, proc =
        if markerFxi.isSome:
          removeVertexMarker()
          saveToUndoHistory()
          setVertexMarker(i)
        else:
          saveToUndoHistory()
      )
      text "x:"
      cbi v.x
      text "y:"
      cbi v.y

      bonkButton("X", proc =
        removeVertexMarker()
        poV.delete(i);
        saveToUndoHistory()
      )

      proc onMouseEnter = setVertexMarker(i)
      proc onMouseLeave =
        removeVertexMarker()
  buildHtml:
    block:
      updateRenderer(true)
      updateRightBoxBody(moph.fixtures.find(fx))
    tdiv(style = "flex: auto; overflow-y: auto; display: flex; flex-flow: column; row-gap: 2px".toCss):
      template poV: untyped = sh.poV
      for i, v in poV.mpairs:
        vertex(i, v, poV)
      tdiv(style = "margin: 3px".toCss):
        bonkButton("Add vertex", proc =
          poV.add([0.0, 0.0])
          removeVertexMarker()
          saveToUndoHistory()
        )

      tdiv(style = "display: flex; flex-flow: row wrap".toCss):
        tdiv(style = "width: 100%".toCss): text "Scale verticies:"
        var scale {.global.}: MapPosition = [1.0, 1.0]
        text "x:"
        bonkInput scale.x, parseFloat
        text "y:"
        bonkInput scale.y, parseFloat

        bonkButton "Apply", proc(): void =
          for v in poV.mitems:
            v.x *= scale.x
            v.y *= scale.y
          removeVertexMarker()
          saveToUndoHistory()

      tdiv(style =
        "display: flex; flex-flow: row wrap; justify-content: space-between"
          .toCss):
        tdiv(style = "width: 100%".toCss): text "Move vertex:"
        var vi {.global.}: int
        bonkInput vi, proc(s: string): int =
          result = s.parseInt
          if result notin 0..poV.high: raise newException(ValueError, "")

        let stuh = proc =
          removeVertexMarker()
          saveToUndoHistory()
          setVertexMarker vi

        bonkButton("Down", proc(): void =
          swap poV[vi], pov[vi + 1]
          inc vi
          stuh()
        , vi == poV.high)
        bonkButton("Up", proc(): void =
          swap poV[vi], pov[vi - 1]
          dec vi
          stuh()
        , vi == poV.low)
        bonkButton("Bottom", proc(): void =
          let v = poV[vi]
          poV.delete vi
          poV.insert v, poV.high + 1
          vi = poV.high
          stuh()
        , vi == poV.high)
        bonkButton("Top", proc(): void =
          let v = poV[vi]
          poV.delete vi
          poV.insert v, poV.low
          vi = poV.low
          stuh()
        , vi == poV.low)

        proc onMouseEnter = setVertexMarker vi
        proc onMouseLeave = removeVertexMarker()


      bonkButton("Set no physics", proc =
        fx.np = true
        saveToUndoHistory()
      )
