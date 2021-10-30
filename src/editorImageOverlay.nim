import
  pkg/karax/[vdom, kdom, vstyles, karax, karaxdsl, jstrutils],
  kkleeApi, bonkElements

proc editorImageOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px; row-gap: 10px".toCss):
  
  span text ("Select an image to overlay onto the editor preview.")
  span text ("The image will be stretched to fit the editor preview's")

  # Add a bonk themed label to the file input
  # it can handle the events for the input
  # Hide the original file input so only the bonk themed one shows
  label(`for` = "kkleeEditorImageOverlayInput"):
    span bonkButton("Choose image", proc = return)
  input(
    `type` = "file",
    id = "kkleeEditorImageOverlayInput",
    accept = "image/*",
    style = "display: none".toCss):
      proc oninput(e: Event; n: VNode) =
        loadEditorImageOverlay(e)
      proc onclick(e: Event; n: VNode) =
        n.value = ""

  bonkButton("Clear image", proc () = 
    loadEditorImageOverlay()
  )

  label(`for` = "kkleeEditorImageOverlayOpacity"):
    span text "Overlay opacity:"
  input(
    id = "kkleeEditorImageOverlayOpacity",
    title = "Overlay opacity",
    class = "compactSlider compactSlider_classic",
    `type` = "range",
    min = "0",
    max = "1",
    step = "0.05"):
      proc oninput(e: Event; n: VNode) =
        try:
          editorImageOverlayOpacity = parseFloat($n.value)
          drawEditorImageOverlay()
        except CatchableError:
          e.target.style.color = "rgb(204, 68, 68)"