import strformat, dom, algorithm, sugar, strutils
import kkleeApi, kkleeMain



proc shapeTableCell(label: string; cell: Element): Element =
  result = document.createElement("tr")

  let labelNode = document.createElement("td")
  labelNode.innerText = label
  labelNode.class = "mapeditor_rightbox_table_leftcell"
  result.appendChild(labelNode)

  let cellNode = document.createElement("td")
  cellNode.appendChild(cell)
  cellNode.class = "mapeditor_rightbox_table_rightcell"
  result.appendChild(cellNode)

proc createBonkButton(label: string; onclick: proc: void): Element =
  result = document.createElement("div")
  result.innerText = label
  result.class = "brownButton brownButton_classic buttonShadow"
  result.onclick = proc(e: Event) = onclick()

afterNewMapObject = hide
afterUpdateLeftBox = rerender

var
  bi: int
  body: MapBody

afterUpdateRightBoxBody = proc(fx: int) =
  if getCurrentBody() notin 0..moph.bodies.high:
    return
  let
    shapeElements = document
      .getElementById("mapeditor_rightbox_shapetablecontainer")
      .getElementsByClassName("mapeditor_rightbox_table_shape")
  bi = getCurrentBody()
  body = bi.getBody

  for i, se in shapeElements.reversed:
    let
      fxi = bi.getBody.fx[i]
      fixture = getFx fxi
    capture fixture, body:
      se.appendChild shapeTableCell("", createBonkButton("Move to body", proc =
        state = StateObject(
          kind: seMoveShape,
          msfx: fixture
        )
        rerender()
      ))
      if fixture.fxShape.shapeType == stypePo:
        se.appendChild shapeTableCell("", createBonkButton("Edit verticies", proc =
          state = StateObject(
            kind: seVertexEditor,
            veb: body, vefx: fixture
          )
          rerender()
        ))

let shapeGeneratorButton = createBonkButton("Generate shape", proc =
  state = StateObject(
    kind: seShapeGenerator,
    sgb: body
  )
  rerender()
)
shapeGeneratorButton.setAttr "style",
  "float: left; margin-bottom: 10px; margin-left: 10px; width: 190px"

document.getElementById("mapeditor_rightbox_shapetablecontainer")
  .insertBefore(
    shapeGeneratorButton,
    document.getElementById(
      "mapeditor_rightbox_shapeaddcontainer").nextSibling
  )




let chat = document.getElementById("newbonklobby_chatbox")

proc moveChatToEditor(e: Event) =
  document.getElementById("mapeditor").insertBefore(
    chat,
    document.getElementById("mapeditor_leftbox")
  )
  chat.setAttribute("style",
    "position: absolute; left: -150px; top: 0%; width: 150px; height: 100%; transform: scale(0.9);"
  )

proc restoreChat(e: Event) =
  document.getelementbyid("newbonklobby").insertbefore(
    chat, document.getelementbyid("newbonklobby_settingsbox")
  )
  chat.setattribute("style", "")

document.getelementbyid("newbonklobby_editorbutton")
  .addEventListener("click", moveChatToEditor)
document.getElementById("mapeditor_close")
  .addEventListener("click", restoreChat)
document.getElementById("hostleaveconfirmwindow_endbutton")
  .addEventListener("click", restoreChat)
document.getElementById("hostleaveconfirmwindow_okbutton")
  .addEventListener("click", restoreChat)
document.getElementById("mapeditor_midbox_testbutton")
  .addEventListener("click", proc(e: Event) =
    chat.style.visibility = "hidden"
  )
document.getElementById("pretty_top_exit")
  .addEventListener("click", proc(e: Event) =
    chat.style.visibility = ""
  )

let colourPicker = document.getElementById("mapeditor_colorpicker")
let colourInput = document.createElement("input")
colourInput.setAttribute("type", "color")
colourInput.id = "kkleeColourInput"
colourPicker.appendChild(colourInput)
colourInput.addEventListener("change", proc(e: Event) =
  let s = $colourInput.value
  setColourPickerColour(parseHexInt(s[1..^1]))
  saveToUndoHistory()
  document.getElementById("mapeditor_colorpicker_cancelbutton").click()
)
