import
  std/[dom, sugar],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements, vertexEditor, shapeGenerator, shapeMultiSelect,
  transferOwnership, platformMultiSelect

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
    seHidden, seVertexEditor, seShapeGenerator, seShapeMultiSelect,
    seTransferOwnership, sePlatformMultiSelect
  StateObject* = ref object
    kind*: StateKindEnum
    fx*: MapFixture
    b*: MapBody



var state* = StateObject(kind: seHidden)

proc hide* =
  state = StateObject(kind: seHidden)
  kxi.redraw()
proc rerender* =
  let s = state
  hide()
  discard window.requestAnimationFrame(proc(_: float) =
    state = s
    kxi.redraw()
  )

proc render: VNode =
  st.width = "200px"
  midboxst.width = "calc(100% - 600px)"

  buildHtml tdiv(style =
    "display: flex; flex-direction: column; height: 100%".toCss):
    tdiv(class = "windowTopBar windowTopBar_classic",
        style = "position: static".toCss):
      text "kklee"

    tdiv(style = (
      "margin: 3px; flex: auto; display: flex; flex-direction: column; " &
      "min-height: 0px; overflow-y: auto").toCss):

      case state.kind
      of seHidden:
        st.width = "0px"
        midboxst.width = "calc(100% - 415px)"
      of seVertexEditor:
        text "Vertex Editor"
        vertexEditor(state.b, state.fx)
      of seShapeGenerator:
        text "Generate a shape"
        shapeGenerator(state.b)
      of seShapeMultiSelect:
        text "Shape multiselect"
        shapeMultiSelect()
      of seTransferOwnership:
        text "Transfer map ownership"
        transferOwnership()
      of sePlatformMultiSelect:
        text "Platform multiselect"
        platformMultiSelect()


    tdiv(style = "margin: 3px".toCss):
      bonkButton("Close", () => (state.kind = seHidden))

setRenderer(render, karaxRoot.id)


rerender()
