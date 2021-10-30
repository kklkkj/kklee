import
  pkg/karax/[vdom, kdom, vstyles, karax, karaxdsl, jstrutils],
  kkleeApi

proc editorImageOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px".toCss):
  
  span text ("Select an image to overlay onto the editor preview.")
  span text ("The image will be stretched to fit the editor preview's " &
  "rectangle, so crop the image before uploading it")

  label(`for` = "kkleeEditorImageOverlayInput"):
    span text "Select files:"
  input(
    `type` = "file",
    id = "kkleeEditorImageOverlayInput",
    accept="image/*"):
      proc onchange(e: Event; n: VNode) =
        loadEditorImageOverlay(e)
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