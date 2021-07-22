import strformat, dom, algorithm, sugar, strutils, math, sequtils
import kkleeApi, kkleeMain, bonkElements, multiSelect

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
  let shapeElements = document
    .getElementById("mapeditor_rightbox_shapetablecontainer")
    .getElementsByClassName("mapeditor_rightbox_table_shape")

  bi = getCurrentBody()
  body = bi.getBody

  for i, se in shapeElements.reversed:
    let
      fxId = bi.getBody.fx[i]
      fixture = getFx fxId
    capture fixture, body:
      proc moveToBody =
        state = StateObject(
          kind: seMoveShape,
          msfx: fixture
        )
        rerender()
      se.appendChild shapeTableCell("",
          createBonkButton("Move to body", moveToBody)
        )
      if fixture.fxShape.shapeType == stypePo:
        proc editVerticies =
          state = StateObject(
            kind: seVertexEditor,
            veb: body, vefx: fixture
          )
          rerender()
        se.appendChild shapeTableCell("",
            createBonkButton("Edit verticies", editVerticies)
          )

  if state.kind == seShapeMultiSelect:
    hide()

# Generate shape button

let shapeGeneratorButton = createBonkButton("Generate shape", proc =
  state = StateObject(
    kind: seShapeGenerator,
    sgb: body
  )
  rerender()
)
shapeGeneratorButton.setAttr("style",
  "float: left; margin-bottom: 5px; margin-left: 10px; width: 190px")

document.getElementById("mapeditor_rightbox_shapetablecontainer")
  .insertBefore(
    shapeGeneratorButton,
    document.getElementById(
      "mapeditor_rightbox_shapeaddcontainer").nextSibling
  )

# Multiselect shapes button

let shapeMultiSelectButton = createBonkButton("Multiselect shapes", proc =
  state = StateObject(kind: seShapeMultiSelect)
  rerender()
)

shapeMultiSelectButton.setAttr "style",
  "float: left; margin-bottom: 5px; margin-left: 10px; width: 190px"

document.getElementById("mapeditor_rightbox_shapetablecontainer")
  .insertBefore(
    shapeMultiSelectButton,
    document.getElementById(
      "mapeditor_rightbox_shapeaddcontainer").nextSibling
  )

document.getElementById("mapeditor_rightbox_shapetablecontainer")
  .addEventListener("click", proc(e: MouseEvent) =
    if state.kind != seShapeMultiSelect: return
    if not e.shiftKey: return

    let
      shapeElements = document
        .getElementById("mapeditor_rightbox_shapetablecontainer")
        .getElementsByClassName("mapeditor_rightbox_table_shape_headerfield")
        .reversed
      bi = getCurrentBody()
      body = bi.getBody
      index = shapeElements.find e.target.Element

    if index == -1: return
    let fx = moph.fixtures[body.fx[index]]

    if not selectedFixtures.contains(fx):
      shapeElements[index].style.border = "4px solid blue"
      selectedFixtures.add fx
    else:
      shapeElements[index].style.border = ""
      selectedFixtures.delete(selectedFixtures.find fx)
  )

# See chat in editor

let chat = document.getElementById("newbonklobby_chatbox")
let parentDocument {.importc: "parent.document".}: Document
var isChatInEditor = false

proc moveChatToEditor(e: Event) =
  if isChatInEditor: return
  isChatInEditor = true;
  document.getElementById("mapeditor").insertBefore(
    chat,
    document.getElementById("mapeditor_leftbox")
  )
  chat.setAttribute("style",
    "position: fixed; left: 0%; top: 0%; width: calc(20% - 100px); height: 90%; transform: scale(0.9);"
  )
  parentDocument.getElementById("adboxverticalleftCurse").style.display = "none"
  # Modifying scrollTop immediately won't work, so I used setTimeout 0ms
  discard setTimeout(proc = document.getElementById(
    "newbonklobby_chat_content").scrollTop = 1e7.int, 0)

proc restoreChat(e: Event) =
  if not isChatInEditor: return
  isChatInEditor = false
  document.getElementById("newbonklobby").insertbefore(
    chat, document.getElementById("newbonklobby_settingsbox")
  )
  chat.setattribute("style", "")
  parentDocument.getElementById("adboxverticalleftCurse").style.display = ""

document.getElementById("newbonklobby_editorbutton")
  .addEventListener("click", moveChatToEditor)
document.getElementById("mapeditor_close")
  .addEventListener("click", restoreChat)
document.getElementById("hostleaveconfirmwindow_endbutton")
  .addEventListener("click", restoreChat)
document.getElementById("hostleaveconfirmwindow_okbutton")
  .addEventListener("click", restoreChat)
document.getElementById("newbonklobby")
  .addEventListener("mouseover", restoreChat)
document.getElementById("mapeditor_midbox_testbutton")
  .addEventListener("click", proc(e: Event) =
    chat.style.visibility = "hidden"
  )
document.getElementById("pretty_top_exit")
  .addEventListener("click", proc(e: Event) =
    chat.style.visibility = ""
  )

# Colour picker

let colourPicker = document.getElementById("mapeditor_colorpicker")
let colourInput = document.createElement("input")
colourInput.setAttribute("type", "color")
colourInput.id = "kkleeColourInput"
colourPicker.appendChild(colourInput)
colourInput.addEventListener("change", proc(e: Event) =
  let strVal = $colourInput.value
  setColourPickerColour(parseHexInt(strVal[1..^1]))
  saveToUndoHistory()
  document.getElementById("mapeditor_colorpicker_cancelbutton").click()
)

# Arithmetic in fields

import mathexpr
let myEvaluator = newEvaluator()

document.getElementById("mapeditor").addEventListener("keydown", proc(
    e: KeyboardEvent) =
  if not (e.shiftKey and e.keyCode == 13):
    return
  let el = document.activeElement
  if not el.classList.contains("mapeditor_field"):
    return

  try:
    let evalRes = myEvaluator.eval($el.value)
    if evalRes.isNaN or evalRes > 1e6 or evalRes < -1e6:
      raise ValueError.newException("Number is NaN or is too big")
    el.value = evalRes.niceFormatFloat()
    el.dispatchEvent(newEvent("input"))
    saveToUndoHistory()
  except CatchableError as err:
    discard
)

# Editor test speed slider

let speedSlider = document.createElement("input").InputElement
speedSlider.`type` = "range"
speedSlider.min = "1"
speedSlider.max = "8"
speedSlider.step = "1"
speedSlider.value = "3"
speedSlider.class = "compactSlider compactSlider_classic"
speedSlider.style.width = "100px"
speedSlider.setAttr("title", "Preview speed")
speedSlider.addEventListener("input", proc(e: Event) =
  editorPreviewTimeMs = parseFloat($speedSlider.value) ^ 3 + 3
)
let rightButtonContainer = document.getElementById("mapeditor_midbox_rightbuttoncontainer")
rightButtonContainer.insertBefore(
  speedSlider,
  document.getElementById("mapeditor_midbox_playbutton")
)

# Arithmetic evaluation tip
let arithmeticTip = document.createElement("div")
arithmeticTip.innerText =
  "You can enter arithmetic into fields, such as 100*2+50, and evaluate it with Shift+Enter"
arithmeticTip.setAttr("style", "font-size: 11px;padding: 0px 10px;")
document.getElementById("mapeditor_rightbox_platformparams")
  .appendChild(arithmeticTip)
