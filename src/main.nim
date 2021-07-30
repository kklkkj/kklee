import
  std/[dom, algorithm, sugar, strutils, math],
  kkleeApi, kkleeMain, bonkElements, multiSelect

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

let
  rightBoxShapeTableContainer =
    docElemById("mapeditor_rightbox_shapetablecontainer")
  mapEditorDiv =
    docElemById("mapeditor")

var
  bi: int
  body: MapBody

afterUpdateRightBoxBody = proc(fx: int) =
  if getCurrentBody() notin 0..moph.bodies.high:
    return
  let shapeElements = rightBoxShapeTableContainer
    .getElementsByClassName("mapeditor_rightbox_table_shape")

  bi = getCurrentBody()
  body = bi.getBody

  for i, se in shapeElements.reversed:
    let
      fxId = bi.getBody.fx[i]
      fixture = getFx fxId
    capture fixture, body:
      if fixture.fxShape.shapeType == stypePo:
        proc editVerticies =
          state = StateObject(
            kind: seVertexEditor,
            b: body, fx: fixture
          )
          rerender()
        se.appendChild shapeTableCell("",
            createBonkButton("Edit verticies", editVerticies)
          )

  multiSelectElementBorders()

# Generate shape button

let shapeGeneratorButton = createBonkButton("Generate shape", proc =
  state = StateObject(
    kind: seShapeGenerator,
    b: body
  )
  rerender()
)
shapeGeneratorButton.setAttr("style",
  "float: left; margin-bottom: 5px; margin-left: 10px; width: 190px")

rightBoxShapeTableContainer
  .insertBefore(
    shapeGeneratorButton,
    docElemById("mapeditor_rightbox_shapeaddcontainer").nextSibling
  )

# Multiselect shapes button

let shapeMultiSelectButton = createBonkButton("Multiselect shapes", proc =
  state = StateObject(kind: seShapeMultiSelect)
  rerender()
)

shapeMultiSelectButton.setAttr "style",
  "float: left; margin-bottom: 5px; margin-left: 10px; width: 190px"

rightBoxShapeTableContainer
  .insertBefore(
    shapeMultiSelectButton,
    docElemById("mapeditor_rightbox_shapeaddcontainer").nextSibling
  )

rightBoxShapeTableContainer
  .addEventListener("click", proc(e: MouseEvent) =
    if state.kind != seShapeMultiSelect or
      fixturesBody != getCurrentBody().getBody: return
    if not e.shiftKey: return

    let
      shapeElements = rightBoxShapeTableContainer
        .getElementsByClassName("mapeditor_rightbox_table_shape_headerfield")
        .reversed()
      body = getCurrentBody().getBody
      index = shapeElements.find e.target.Element

    if index == -1: return
    let fx = moph.fixtures[body.fx[index]]

    if not selectedFixtures.contains(fx):
      selectedFixtures.add fx
    else:
      selectedFixtures.delete(selectedFixtures.find fx)
    multiSelectElementBorders()
  )

# See chat in editor

let chat = docElemById("newbonklobby_chatbox")
let parentDocument {.importc: "parent.document".}: Document
var isChatInEditor = false

proc moveChatToEditor(e: Event) =
  if isChatInEditor: return
  isChatInEditor = true;
  mapEditorDiv.insertBefore(
    chat,
    docElemById("mapeditor_leftbox")
  )
  chat.setAttribute("style",
    "position: fixed; left: 0%; top: 0%; width: calc(20% - 100px); height: 90%; transform: scale(0.9);"
  )
  parentDocument.getElementById("adboxverticalleftCurse").style.display = "none"
  # Modifying scrollTop immediately won't work, so I used setTimeout 0ms
  discard setTimeout(proc = docElemById(
    "newbonklobby_chat_content").scrollTop = 1e7.int, 0)

proc restoreChat(e: Event) =
  if not isChatInEditor: return
  isChatInEditor = false
  docElemById("newbonklobby").insertbefore(
    chat, docElemById("newbonklobby_settingsbox")
  )
  chat.setattribute("style", "")
  parentDocument.getElementById("adboxverticalleftCurse").style.display = ""

docElemById("newbonklobby_editorbutton")
  .addEventListener("click", moveChatToEditor)

docElemById("mapeditor_close")
  .addEventListener("click", restoreChat)
docElemById("hostleaveconfirmwindow_endbutton")
  .addEventListener("click", restoreChat)
docElemById("hostleaveconfirmwindow_okbutton")
  .addEventListener("click", restoreChat)

docElemById("newbonklobby")
  .addEventListener("mouseover", restoreChat)

docElemById("mapeditor_midbox_testbutton")
  .addEventListener("click", proc(e: Event) =
    chat.style.visibility = "hidden"
  )
docElemById("pretty_top_exit").addEventListener("click", proc(e: Event) =
  chat.style.visibility = ""
)

# Colour picker

let colourPicker = docElemById("mapeditor_colorpicker")
let colourInput = document.createElement("input")
colourInput.setAttribute("type", "color")
colourInput.id = "kkleeColourInput"
colourPicker.appendChild(colourInput)
colourInput.addEventListener("change", proc(e: Event) =
  let strVal = $colourInput.value
  setColourPickerColour(parseHexInt(strVal[1..^1]))
  saveToUndoHistory()
  docElemById("mapeditor_colorpicker_cancelbutton").click()
)

# Arithmetic in fields

import mathexpr
let myEvaluator = newEvaluator()

mapEditorDiv.addEventListener("keydown", proc(
    e: KeyboardEvent) =
  if not (e.shiftKey and e.key == "Enter"):
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
  except CatchableError:
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
let rightButtonContainer =
  docElemById("mapeditor_midbox_rightbuttoncontainer")
rightButtonContainer.insertBefore(
  speedSlider,
  docElemById("mapeditor_midbox_playbutton")
)

# Tips

let
  tipsList = document.createElement("ul")
  arithmeticTip = document.createElement("li")
  shortcutsTip = document.createElement("li")

arithmeticTip.innerText =
  "You can enter arithmetic into fields, such as 100*2+50, and evaluate it with Shift+Enter"
shortcutsTip.innerText =
  "Keyboard shortcuts: Save - Ctrl+S, Preview - Space, Play - Shift+Space"

tipsList.appendChild(arithmeticTip)
tipsList.appendChild(shortcutsTip)
tipsList.setAttr("style", "font-size: 11px;padding: 10px 15px;")
docElemById("mapeditor_rightbox_platformparams").appendChild(tipsList)

# Keyboard shortcuts

mapEditorDiv.setAttr("tabindex", "0")
mapEditorDiv.addEventListener("keydown", proc(ev: KeyboardEvent) =
  if ev.target != mapEditorDiv:
    return
  ev.preventDefault()
  if ev.ctrlKey and ev.key == "s":
    docElemById("mapeditor_midbox_savebutton").click()
    docElemById("mapeditor_save_window_save").click()
  elif ev.shiftKey and ev.key == " ":
    docElemById("mapeditor_midbox_testbutton").click()
    mapEditorDiv.blur()
  elif ev.key == " ":
    docElemById("mapeditor_midbox_playbutton").click()
)
