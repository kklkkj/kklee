import
  std/[dom, sugar],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements, moveShape, vertexEditor, shapeGenerator, multiSelect

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
    seHidden, seVertexEditor, seMoveShape, seShapeGenerator, seShapeMultiSelect,
    seShapeMultiDuplicate
  StateObject* = ref object
    kind*: StateKindEnum
    fx*: MapFixture
    b*: MapBody



var state* = StateObject(kind: seHidden)

proc rerender* =
  kxi.redraw()
proc hide* =
  state = StateObject(kind: seHidden)
  rerender()

proc render: VNode =
  st.width = "200px"
  midboxst.width = "calc(100% - 600px)"

  buildHtml(tdiv(style =
    "display: flex; flex-direction: column; height: 100%; overflow-y: auto".toCss)):
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
        vertexEditor(state.b, state.fx)
      of seMoveShape:
        text "Move shape to another body"
        moveShape(state.fx, state.b)
      of seShapeGenerator:
        text "Generate a shape"
        shapeGenerator(state.b)
      of seShapeMultiSelect:
        text "Shape multiselect"
        shapeMultiSelect()
      of seShapeMultiDuplicate:
        text "Shape multi duplicate and select"
        shapeMultiDuplicate(state.fx, state.b)

      tdiv(style = "width: 100%; margin-top: 10px".toCss):
        bonkButton("Close", () => (state.kind = seHidden))

setRenderer(render, karaxRoot.id)


rerender()
