import strformat, dom, algorithm, sugar, strutils, options, math, sequtils
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements, moveShape, vertexEditor

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
st.borderTopLeftRadius = "3px"
st.borderTopRightRadius = "3px"
root.class = "buttonShadow"
document.getElementById("mapeditor").appendChild(root)

let midboxst = document.getElementById("mapeditor_midbox").style
midboxst.width = "calc(100% - 415px)"
midboxst.transition = "width 0.5s"

type
  StateKindEnum* = enum
    seHidden, seVertexEditor, seMoveShape
  StateObject* = ref object
    case kind*: StateKindEnum
    of seHidden: discard
    of seVertexEditor:
      vefx*: MapFixture
      veb*: MapBody
    of seMoveShape:
      msfx*: MapFixture
      msb*: MapBody



var state* = StateObject(kind: seHidden)

proc rerender* = kxi.redraw()
proc hide* =
  state = StateObject(kind: seHidden)
  rerender()





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
        vertexEditor(state.veb, state.vefx)
      of seMoveShape:
        text "Move shape to another body"
        moveShape(state.msfx, state.msb)

      tdiv(style = "width: 100%; margin-top: 10px".toCss):
        bonkButton("Close", () => (state.kind = seHidden))

setRenderer(render, karaxRoot.id)


rerender()
