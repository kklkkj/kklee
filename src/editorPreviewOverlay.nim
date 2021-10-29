import
  std/[strformat],
  pkg/karax/[karaxdsl, vdom, vstyles],
  kkleeApi

proc editorPreviewOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px".toCss):
  span text &"<Template text>"
