import
  pkg/karax/[kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson],
  kkleeApi
  
proc editorPreviewOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px".toCss):
  
  label(`for` = "kkleeEditorPreviewOverlayInput"):
    span text "Select files:"
  input(
    class = "brownButton brownButton_classic buttonShadow",
    `type` = "file",
    id = "kkleeEditorPreviewOverlayInput",
    accept="image/*"):
      proc onchange(ev: Event; n: VNode) =
        loadEditorPreviewOverlay()
  label(`for` = "kkleeEditorPreviewOverlayOpacity"):
    span text "Opacity:"
  input(
    id = "kkleeEditorPreviewOverlayOpacity",
    class = "compactSlider compactSlider_classic",
    `type` = "range",
    min = "0",
    max = "1",
    step = "0.05",
    value = "0.75", # This is not working :/
    title = "Opacity"):
      proc onchange(ev: Event; n: VNode) =
        editorPreviewOverlayOpacity = parseFloat(n.value)
        drawEditorPreviewOverlay()