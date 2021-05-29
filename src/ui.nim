import strformat, dom, algorithm, sugar, strutils, options
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi

let root* = document.createElement("div")
let karaxRoot* = document.createElement("div")
karaxRoot.id = "kkleeRoot"
root.appendChild(karaxRoot)
let st = root.style
st.width = "0px"
st.height = "100%"
st.transition = "width 0.5s"
st.position = "relative"
st.backgroundColor = "#cfd8dc"
root.class = "buttonShadow"
document.getElementById("mapeditor").appendChild(root)

let midboxst = document.getElementById("mapeditor_midbox").style
midboxst.width = "calc(100% - 415px)"
midboxst.transition = "width 0.5s"

type
  StateKindEnum* = enum
    seHidden, seVertexEditor
  StateObject* = ref object
    case kind*: StateKindEnum
    of seHidden: discard
    of seVertexEditor:
      fxi*, bi*: int

var state* = StateObject(kind: seHidden)


proc bonkButton(label: string, onClick: proc): VNode =
  buildHtml(tdiv(class = "brownButton brownButton_classic buttonShadow")):
    text label
    proc onClick = onClick()

proc bonkInput[T](variable: var T; parser: string -> T): VNode =
  buildHtml(tdiv):
    input(class = "mapeditor_field mapeditor_field_spacing_bodge fieldShadow",
        value = $variable):
      proc onInput(e: Event; n: VNode) =
        try:
          variable = parser $n.value
          e.target.style.color = ""
        except CatchableError:
          e.target.style.color = "rgb(204, 68, 68)"

var markerFxi: Option[int]

proc removeVertexMarker =
  if markerFxi.isNone: return
  let mfxi = markerFxi.get
  for i, j in state.bi.getBody.fx:
    if j == mfxi:
      state.bi.getBody.fx.delete i
      break
  mapObject.physics.shapes.delete mfxi.getFx.sh
  mapObject.physics.fixtures.delete mfxi
  markerFxi = none int
  updateRenderer(true)

proc setVertexMarker(p: MapPosition) =
  removeVertexMarker()
  mapObject.physics.shapes.add MapShape(
    stype: "ci", ciR: 3.0, ciSk: false, c: p
  )
  mapObject.physics.fixtures.add MapFixture(
    n: "temp marker", np: true, f: 0xff0000,
    sh: mapObject.physics.shapes.high
  )
  let fxi = mapObject.physics.fixtures.high
  state.bi.getBody.fx.add fxi
  markerFxi = some fxi
  updateRenderer(true)

proc vertexEditor: VNode =
  proc vertex(i: int; v: var MapPosition; poV: var seq[MapPosition]): VNode =
    buildHtml tdiv(style = "display: flex; flex-flow: row wrap".toCss):
      span(style = "width: 40px".toCss):
        text &"{i}."
      text "X:"
      bonkInput v.x, parseFloat
      text "Y:"

      bonkInput v.y, parseFloat
      bonkButton("X", () => poV.delete(i))

      proc onMouseEnter = setVertexMarker(v)
      proc onMouseLeave =
        removeVertexMarker()
  buildHtml:
    block:
      updateRenderer(true)
      updateRightBoxBody(state.fxi)
    tdiv(style = "flex: auto; overflow-y: auto;".toCss):
      template poV: untyped = state.fxi.getFx.fxShape.poV
      for i, v in poV.mpairs:
        vertex(i, v, poV)


proc render: VNode =
  st.width = "200px"
  midboxst.width = "calc(100% - 580px)"

  buildHtml(tdiv(style =
    "display: flex; flex-direction: column; height: 100%".toCss)):
    tdiv(class = "windowTopBar windowTopBar_classic",
        style = "position: static".toCss):
      text "kklee"

    tdiv(style = "margin: 3px; flex: auto; display: flex; flex-direction: column; min-height: 0px".toCss):

      case state.kind
      of seHidden:
        st.width = "0px"
        midboxst.width = "calc(100% - 415px)"
      of seVertexEditor:
        text "Vertex Editor"
        vertexEditor()

      tdiv(style = "width: 100%".toCss):
        bonkButton("Close", () => (state.kind = seHidden))

setRenderer(render, karaxRoot.id)

proc rerender* = kxi.redraw()

rerender()
