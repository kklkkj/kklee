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
        var img: ImageElement = ImageElement()
        img.width = 738
        img.height = 508
        # TODO: Fix. This is horrible.
        # TODO: Add window.kklee.editorPreviewOutline to kkleeApi
        # editorPreviewOutline.clear()
