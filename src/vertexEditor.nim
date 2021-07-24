import
  std/[dom, sugar, strutils, options, math, algorithm, sequtils],
  pkg/karax/[kbase, karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements


var
  markerFxId: Option[int]
  b: MapBody
  fx: MapFixture
  sh: MapShape

proc removeVertexMarker =
  if markerFxId.isNone: return
  let mfxId = markerFxId.get
  for i, j in b.fx:
    if j == mfxId:
      b.fx.delete i
      break
  moph.shapes.delete mfxId.getFx.sh
  moph.fixtures.delete mfxId
  markerFxId = none int
  updateRenderer(true)

proc setVertexMarker(vId: int) =
  removeVertexMarker()
  let
    v = sh.poV[vId]
    # Only scaled marker positions
    smp: MapPosition = [
      v.x * sh.poS,
      v.y * sh.poS
    ]
    markerPos: MapPosition = [
      smp.x * cos(sh.a) - smp.y * sin(sh.a) + sh.c.x,
      smp.x * sin(sh.a) + smp.y * cos(sh.a) + sh.c.y
    ]
  moph.shapes.add MapShape(
    stype: "ci", ciR: 3.0, ciSk: false, c: markerPos
  )
  moph.fixtures.add MapFixture(
    n: "temp marker", np: true, f: 0xff0000,
    sh: moph.shapes.high
  )
  let fxId = moph.fixtures.high
  b.fx.add fxId
  markerFxId = some fxId
  updateRenderer(true)

proc mergeShapes(b: MapBody) =
  # This is buggy because the output verticies might be ordered in a way
  # that causes it to be not rendered corrently...
  sh.poV.applyIt [it.x * sh.poS, it.y * sh.poS].MapPosition
  sh.poS = 1.0

  var i = 0
  while i < b.fx.len:
    let
      fxId = b.fx[i]
      cfx = fxId.getFx
      csh = cfx.fxShape
    if cfx.f != fx.f or cfx == fx or
      not cfx.np:
      inc i
      continue

    var npoV: seq[MapPosition]
    case csh.shapeType
    of stypePo:
      npoV = csh.poV.mapIt [it.x * csh.poS, it.y * csh.poS].MapPosition
    of stypeBx:
      npoV = @[
        [csh.bxW / -2, csh.bxH / -2], [csh.bxW / 2, csh.bxH / -2],
        [csh.bxW / 2, csh.bxH / 2], [csh.bxW / -2, csh.bxH / 2]
      ]
    else:
      inc i
      continue

    for c in npoV.mitems:
      c = [
        c.x * cos(csh.a) - c.y * sin(csh.a),
        c.x * sin(csh.a) + c.y * cos(csh.a)
      ]
      c = [c.x + csh.c.x - sh.c.x, c.y + csh.c.y - sh.c.y]
      c = [
        c.x * cos(-sh.a) - c.y * sin(-sh.a),
        c.x * sin(-sh.a) + c.y * cos(-sh.a)
      ]
    sh.poV.add(npoV & npoV[0] & sh.poV[^1])
    deleteFx fxId

  saveToUndoHistory()


proc vertexEditor*(veb: var MapBody; vefx: var MapFixture): VNode =
  b = veb
  fx = vefx
  sh = fx.fxShape
  proc vertex(i: int; v: var MapPosition; poV: var seq[MapPosition]): VNode =
    buildHtml tdiv(style = "display: flex; flex-flow: row wrap".toCss):
      span(style = "width: 27px; font-size: 12;".toCss):
        text $i
      template cbi(va): untyped = bonkInput(va, prsFLimited, proc =
        if markerFxId.isSome:
          removeVertexMarker()
          saveToUndoHistory()
          setVertexMarker(i)
        else:
          saveToUndoHistory()
      , niceFormatFloat)
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
  updateRenderer(true)
  updateRightBoxBody(moph.fixtures.find(fx))
  return buildHtml tdiv(style =
    "flex: auto; overflow-y: auto; display: flex; flex-flow: column; row-gap: 2px"
      .toCss
    ):
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
      bonkInput scale.x, prsFLimitedPositive, nil, niceFormatFloat
      text "y:"
      bonkInput scale.y, prsFLimitedPositive, nil, niceFormatFloat

      bonkButton "Apply", proc(): void =
        for v in poV.mitems:
          v.x = (v.x * scale.x).clamp(-1e6, 1e6)
          v.y = (v.y * scale.y).clamp(-1e6, 1e6)
        removeVertexMarker()
        saveToUndoHistory()

    tdiv(style =
      "display: flex; flex-flow: row wrap; justify-content: space-between"
        .toCss):
      tdiv(style = "width: 100%".toCss): text "Move vertex:"
      var vId {.global.}: int
      bonkInput(vId, proc(s: string): int =
        result = s.parseInt
        if result notin 0..poV.high: raise newException(ValueError, "")
      , nil, v => $v)

      let stuh = proc =
        removeVertexMarker()
        saveToUndoHistory()
        setVertexMarker vId

      bonkButton("Down", proc(): void =
        swap poV[vId], pov[vId + 1]
        inc vId
        stuh()
      , vId == poV.high)
      bonkButton("Up", proc(): void =
        swap poV[vId], pov[vId - 1]
        dec vId
        stuh()
      , vId == poV.low)
      bonkButton("Bottom", proc(): void =
        let v = poV[vId]
        poV.delete vId
        poV.insert v, poV.high + 1
        vId = poV.high
        stuh()
      , vId == poV.high)
      bonkButton("Top", proc(): void =
        let v = poV[vId]
        poV.delete vId
        poV.insert v, poV.low
        vId = poV.low
        stuh()
      , vId == poV.low)

      proc onMouseEnter = setVertexMarker vId
      proc onMouseLeave = removeVertexMarker()

    bonkButton("Reverse order", proc =
      poV.reverse()
      saveToUndoHistory()
    )
    bonkButton("Set no physics", proc =
      fx.np = true
      saveToUndoHistory()
    )

    bonkButton("(BUGGY!) Merge with no-physics shapes of same colour", () =>
      mergeShapes(b))
