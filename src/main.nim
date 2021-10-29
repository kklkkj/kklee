import
  std/[dom, algorithm, sugar, strutils, math],
  kkleeApi, kkleeMain, bonkElements, shapeMultiSelect, platformMultiSelect

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
    capture fixture, body, fxId:
      if fixture.fxShape.shapeType == stypePo:
        proc editVerticies =
          state = StateObject(
            kind: seVertexEditor,
            b: body, fx: fixture
          )
          rerender()
        se.appendChild shapeTableCell("",
            createBonkButton("Edit vertices", editVerticies))
      proc editCapZone =
        var shapeCzId = -1
        for i, cz in mapObject.capZones:
          if cz.i == fxId:
            shapeCzId = i
            break
        if shapeCzId == -1:
          mapObject.capZones.add MapCapZone(
            n: "Cap Zone", ty: cztNormal, l: 10, i: fxId)
          shapeCzId = mapObject.capZones.high
          updateLeftBox()
          updateRenderer(true)
          saveToUndoHistory()
        document.getElementsByClassName("mapeditor_listtable")[^1]
          .children[0].children[shapeCzId].Element.click()
      se.appendChild shapeTableCell("",
        createBonkButton("Capzone", editCapZone))
      if fixture.fxShape.shapeType == stypeBx:
        proc rectToPoly =
          let bx = fixture.fxShape
          moph.shapes[fixture.sh] = MapShape(
            stype: $stypePo,
            a: bx.a,
            c: bx.c,
            poS: 1.0,
            poV: @[[-bx.bxW/2, -bx.bxH/2], [bx.bxW/2, -bx.bxH/2],
                  [bx.bxW/2, bx.bxH/2], [-bx.bxW/2, bx.bxH/2]]
          )
          saveToUndoHistory()
          updateRightBoxBody(fxId)
        se.appendChild shapeTableCell("",
          createBonkButton("To polygon", rectToPoly))


  shapeMultiSelectElementBorders()

# Platform multiselect

let platformMultiSelectButton = createBonkButton("Multiselect", proc =
  state = StateObject(kind: sePlatformMultiSelect)
  rerender()
)
platformMultiSelectButton.style.margin = "3px"
platformMultiSelectButton.style.width = "100px"

proc initPlatformMultiSelect =
  let platformsContainer = docElemById("mapeditor_leftbox_platformtable")
  if platformsContainer.isNil: return
  platformsContainer.appendChild(platformMultiSelectButton)
  platformMultiSelectElementBorders()

  platformsContainer.children[0].addEventListener("click", proc(e: Event) =
    let e = e.MouseEvent
    if not e.shiftKey: return
    if state.kind != sePlatformMultiSelect:
      state = StateObject(kind: sePlatformMultiSelect)
      rerender()

    let index = platformsContainer.children[0].children.find e.target.parentNode
    if index == -1: return
    let b = moph.bro[index].getBody

    if b notin selectedBodies:
      selectedBodies.add b
    else:
      selectedBodies.delete(selectedBodies.find b)
    platformMultiSelectElementBorders()
  )

afterUpdateLeftBox = proc =
  # This fixes the bug where shapeMultiSelectElementBorders would throw an
  # error when the right box was not updated to show the currently selected
  # platform. This would occur when the user creates a new platform while
  # shape multi-select is open.
  if docElemById("mapeditor_rightbox_platformparams").style.visibility !=
      "none" and
      getCurrentBody() in 0..moph.bodies.high and
      body != getCurrentBody().getBody:
    updateRightBoxBody(-1)

  initPlatformMultiSelect()

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

# Shape multiselect

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
  .addEventListener("click", proc(e: Event) =
    let e = e.MouseEvent
    if not e.shiftKey: return
    fixturesBody = getCurrentBody().getBody
    if state.kind != seShapeMultiSelect:
      state = StateObject(kind: seShapeMultiSelect)
      rerender()

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
    shapeMultiSelectElementBorders()
  )

# Total mass of platform value textbox

let totalMassTextbox = document.createElement("input")
totalMassTextbox.style.width = "60px"
totalMassTextbox.style.backgroundColor = "gray"
docElemById("mapeditor_rightbox_table_dynamic").children[0]
  .appendChild shapeTableCell("Platform mass", totalMassTextbox)
totalMassTextbox.addEventListener("mouseenter", proc(e: Event) =
  setEditorExplanation(
    "[kklee]\n" &
    "This shows the total mass of the platform. You can't edit this directly."
  )
)

totalMassTextbox.addEventListener("mousemove", proc(e: Event) =
  var totalMass = 0.0
  let body = getCurrentBody().getBody
  for fxId in body.fx:
    let
      fx = fxId.getFx
    if fx.np:
      continue
    let
      sh = fx.fxShape
      density = if fx.de == jsNull: body.de
                else: fx.de
      area = case sh.shapeType
        of stypeBx:
          sh.bxH * sh.bxW
        of stypeCi:
          PI * sh.ciR ^ 2
        of stypePo:
          var area = 0.0
          for i, p1 in sh.poV:
            let p2 = sh.poV[if i == sh.poV.high: 0 else: i + 1]
            area += p1.x * p2.y - p2.x * p1.y
          area / 2
      mass = area * density
    totalMass += mass
  totalMassTextbox.value = cstring $totalMass
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
    ("position: fixed; left: 0%; top: 0%; width: calc(20% - 100px); " &
     "height: 90%; transform: scale(0.9);")
  )
  parentDocument.getElementById("adboxverticalleftCurse").style.display = "none"
  # Modifying scrollTop immediately won't work, so I used setTimeout 0ms
  discard setTimeout(proc = docElemById(
    "newbonklobby_chat_content").scrollTop = 1e7.int, 0)

proc restoreChat(e: Event) =
  if not isChatInEditor: return
  isChatInEditor = false
  docElemById("newbonklobby").insertBefore(
    chat, docElemById("newbonklobby_settingsbox")
  )
  chat.setAttribute("style", "")
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
docElemById("gamerenderer")
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
myEvaluator.addFunc("rand", mathExprJsRandom, 0)

mapEditorDiv.addEventListener("keydown", proc(e: Event) =
  let e = e.KeyboardEvent
  if not (e.shiftKey and e.key == "Enter"):
    return
  let el = document.activeElement
  if not el.classList.contains("mapeditor_field"):
    return

  try:
    let evalRes = myEvaluator.eval($el.value)
    if evalRes.isNaN or evalRes > 1e6 or evalRes < -1e6:
      raise ValueError.newException("Number is NaN or is too big")
    el.value = cstring evalRes.niceFormatFloat()
    el.dispatchEvent(newEvent("input"))
    saveToUndoHistory()
  except CatchableError:
    discard
)

# Editor test speed slider

let speedSlider = document.createElement("input").InputElement
speedSlider.`type` = "range"
speedSlider.min = "0"
speedSlider.max = "8"
speedSlider.step = "1"
speedSlider.value = "3"
speedSlider.class = "compactSlider compactSlider_classic"
speedSlider.style.width = "100px"
speedSlider.setAttr("title", "Preview speed")
speedSlider.addEventListener("input", proc(e: Event) =
  # Default is 30
  let n = parseFloat($speedSlider.value)
  editorPreviewTimeMs = if n == 0.0: 0.0
                        else: n ^ 3 + 3.0
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

proc addTip(t: string) =
  let el = document.createElement("ul")
  el.innerText = t
  tipsList.appendChild(el)
addTip(
  "You can enter arithmetic into fields, such as 100*2+50, and evaluate it " &
  "with Shift+Enter"
)
addTip(
  "Keyboard shortcuts: Save - Ctrl+S, Preview - Space, Play - Shift+Space, " &
  "Return to editor after play - Shift+Esc"
)
addTip(
  "Use up/down arrows in number fields to increase/decrease value - " &
  "Just arrow: 10, Shift+Arrow: 1, Ctrl+Arrow: 100, Ctrl+Shift+Arrow: 0.1"
)

tipsList.setAttr("style", "font-size: 11px;padding: 10px 15px;")
docElemById("mapeditor_rightbox_platformparams").appendChild(tipsList)

# Keyboard shortcuts

mapEditorDiv.setAttr("tabindex", "0")
mapEditorDiv.addEventListener("keydown", proc(e: Event) =
  let e = e.KeyboardEvent
  block:
    if e.target != mapEditorDiv or
        docElemById("gamerenderer").style.visibility == "inherit":
      break
    if e.ctrlKey and e.key == "s":
      docElemById("mapeditor_midbox_savebutton").click()
      docElemById("mapeditor_save_window_save").click()
    elif e.shiftKey and e.key == " ":
      docElemById("mapeditor_midbox_testbutton").click()
    elif e.key == " ":
      docElemById("mapeditor_midbox_playbutton").click()
    else:
      break
    e.preventDefault()
  block:
    if not document.activeElement.classList.contains("mapeditor_field"):
      break
    let val = try: parseFloat $e.target.value
              except: break
    let amount =
      if e.ctrlKey and e.shiftKey: 0.1
      elif e.shiftKey: 1
      elif e.ctrlKey: 100
      else: 10
    if e.key == "ArrowUp":
      e.target.value = cstring $(val + amount)
    elif e.key == "ArrowDown":
      e.target.value = cstring $(val - amount)
    dispatchInputEvent(e.target)
)

# Return to map editor after clicking play
document.addEventListener("keydown", proc(e: Event) =
  let e = e.KeyboardEvent
  if docElemById("gamerenderer").style.visibility == "inherit" and
      e.shiftKey and e.key == "Escape":
    e.preventDefault()
    docElemById("pretty_top_exit").click()
    mapEditorDiv.focus()
)

# Transfer map ownership button
proc openTransferOwnership =
  state = StateObject(kind: seTransferOwnership)
  rerender()
docElemById("mapeditor_rightbox_mapparams").appendChild(
  shapeTableCell("", createBonkButton("Transfer ownership",
      openTransferOwnership)))

# Map size info
proc openMapSizeInfo =
  state = StateObject(kind: seMapSizeInfo)
  rerender()
docElemById("mapeditor_rightbox_mapparams").appendChild(
  shapeTableCell("", createBonkButton("Map size info",
      openMapSizeInfo)))

# Map backup loader
proc openBackupLoader =
  state = StateObject(kind: seBackups)
  rerender()
docElemById("mapeditor_rightbox_mapparams").appendChild(
  shapeTableCell("", createBonkButton("Load map backup",
      openBackupLoader)))


# Editor preview image overlay 
proc openEditorImageOverlay =
  state = StateObject(kind: seEditorImageOverlay)
  rerender()
docElemById("mapeditor_rightbox_mapparams").appendChild(
  shapeTableCell("", createBonkButton("Image overlay",
      openEditorImageOverlay)))

# Make map editor explanation text selectable
docElemById("mapeditor_midbox_explain").setAttr("style", "user-select: text")

# Fullscreen button

let fullscreenButton = createBonkButton("⛶", toggleFullPage)
let fbs = fullscreenButton.style
fbs.position = "absolute"
fbs.right = "350px"
fbs.top = "0px"
fbs.height = "100%"
fbs.width = "40px"
fbs.fontSize = "30"
docElemById("pretty_top_bar").appendChild(fullscreenButton)

# Fix chat box autofill
docElemById("newbonklobby_chat_input").setAttr("autocomplete", "off")
docElemById("ingamechatinputtext").setAttr("autocomplete", "off")

# Add max height for colour picker's existing colours container

let existingColoursContainer =
  docElemById("mapeditor_colorpicker_existingcontainer")
existingColoursContainer.style.maxHeight = "150px"
existingColoursContainer.style.overflowY = "scroll"
