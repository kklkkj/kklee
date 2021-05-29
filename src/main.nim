import strformat, dom, algorithm, sugar
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

afterNewMapObject = proc =
  state.kind = seHidden
  rerender()

afterUpdateRightBoxBody = proc(fx: int) =
  if getCurrentBody() notin 0..mapObject.physics.bodies.high:
    return
  let shapeElements = document
    .getElementById("mapeditor_rightbox_shapetablecontainer")
    .getElementsByClassName("mapeditor_rightbox_table_shape")

  for i, se in shapeElements.reversed:
    let
      bi = getCurrentBody()
      fxi = bi.getBody.fx[i]
      fixture = getFx fxi
    if fixture.fxShape.shapeType == stypePo:
      capture fxi, bi:
        se.appendChild shapeTableCell("Verticies", createBonkButton("Edit", proc =
          state = StateObject(
            kind: seVertexEditor, bi: bi, fxi: fxi
          )
          rerender()
        ))
