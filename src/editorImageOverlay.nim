import
  pkg/karax/[vdom, kdom, vstyles, karax, karaxdsl, jstrutils],
  kkleeApi
  
proc editorImageOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px".toCss):
  
  label(`for` = "kkleeEditorImageOverlayInput"):
    span text "Select files:"
  input(
    class = "brownButton brownButton_classic buttonShadow",
    `type` = "file",
    id = "kkleeEditorImageOverlayInput",
    accept="image/*"):
      proc onchange(ev: Event; n: VNode) =
        loadEditorImageOverlay()
  label(`for` = "kkleeEditorImageOverlayOpacity"):
    span text "Opacity:"
  input(
    id = "kkleeEditorImageOverlayOpacity",
    class = "compactSlider compactSlider_classic",
    `type` = "range",
    min = "0",
    max = "1",
    step = "0.05",
    value = "0.75", # This is not working :/
    title = "Opacity"):
      proc onchange(ev: Event; n: VNode) =
        editorImageOverlayOpacity = parseFloat(n.value)
        drawEditorImageOverlay()