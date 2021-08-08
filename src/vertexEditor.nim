import
  std/[dom, sugar, strutils, options, math, algorithm, sequtils],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
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
  if vId notin 0..sh.poV.high:
    return
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

proc roundCorners(poV: seq[MapPosition]; r: float; prec: float): seq[MapPosition] =
  for i, p in poV:
    let
      p1 = poV[floorMod(i - 1, poV.len)]
      p2 = poV[floorMod(i + 1, poV.len)]
      dp1 = [p.x - p1.x, p.y - p1.y].MapPosition
      dp2 = [p.x - p2.x, p.y - p2.y].MapPosition
      pp1 = hypot(dp1.x, dp1.y)
      pp2 = hypot(dp2.x, dp2.y)
      angle = arctan2(dp1.y, dp1.x) -
              arctan2(dp2.y, dp2.x)
    var
      radius = r
      segment = radius / abs(tan(angle / 2))
      segmentMax = min(pp1, pp2) / 2
    if segment > segmentMax:
      segment = segmentMax
      radius = segment * abs(tan(angle / 2))
    let
      po = hypot(radius, segment)
      c1 = [p.x - dp1.x * segment / pp1,
            p.y - dp1.y * segment / pp1].MapPosition
      c2 = [p.x - dp2.x * segment / pp2,
            p.y - dp2.y * segment / pp2].MapPosition
      d = [p.x * 2 - c1.x - c2.x,
           p.y * 2 - c1.y - c2.y].MapPosition
      pc = hypot(d.x, d.y)
      o = [p.x - d.x * po / pc,
           p.y - d.y * po / pc].MapPosition
    var
      startAngle = arctan2(c1.y - o.y, c1.x - o.x)
      endAngle = arctan2(c2.y - o.y, c2.x - o.x)
      sweepAngle = endAngle - startAngle
    if sweepAngle > PI:
      sweepAngle -= 2 * PI
    elif sweepAngle < -PI:
      sweepAngle += 2 * PI

    result.add c1
    let pointsCount = abs(sweepAngle * prec.float / (2 * PI)).ceil.int
    for pointI in 1..pointsCount:
      let
        t = pointI / (pointsCount + 1)
        a = startAngle + sweepAngle * t
      result.add [o.x + radius * cos(a),
                  o.y + radius * sin(a)].MapPosition
    result.add c2

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

  template poV: untyped = sh.poV
  if poV.len == 0:
    poV.add [0.0, 0.0].MapPosition

  return buildHtml tdiv(style =
    "flex: auto; overflow-y: auto; display: flex; flex-flow: column; row-gap: 2px"
      .toCss
  ):
    ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
      li text "Note: the list of verticies must be in a clockwise direction"
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
      bonkInput scale.x, prsFLimited, nil, niceFormatFloat
      text "y:"
      bonkInput scale.y, prsFLimited, nil, niceFormatFloat

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
      if vId notin 0..poV.high:
        vId = 0
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

    tdiv(style = "padding: 5px 0px".toCss):
      var
        prec {.global.}: float = 20.0
        radius {.global.}: float = 20.0
      text "Radius"
      bonkInput(radius, prsFLimitedPositive, nil, niceFormatFloat)
      br()
      text "Precision"
      bonkInput(prec, prsFLimitedPositive, nil, niceFormatFloat)
      bonkButton("Round corners", proc =
        poV = roundCorners(poV, radius, prec)
        saveToUndoHistory()
        updateRenderer(true)
      )
