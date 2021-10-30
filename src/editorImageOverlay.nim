import
  std/[strutils, strformat],
  pkg/karax/[vdom, kdom, vstyles, karax, karaxdsl],
  bonkElements


# Load an image from an <input>'s onInput or onChange event
proc loadEditorImageOverlay*(e: Event)
    {.importc: "window.kklee.editorImageOverlay.loadImage".}
# If there are no parameters, it will reset the image to nothing
proc loadEditorImageOverlay*()
    {.importc: "window.kklee.editorImageOverlay.loadImage".}
proc updateSpriteSettings*()
    {.importc: "window.kklee.editorImageOverlay.updateSpriteSettings".}

type editorImageOverlayObject = ref object
  x, y, w, h, ogW, ogH, opacity: float
  imageState: cstring

var st*
    {.importc: "window.kklee.editorImageOverlay".}: editorImageOverlayObject



proc editorImageOverlay*: VNode = buildHtml tdiv(style =
  "display: flex; flex-flow: column; font-size: 16px; row-gap: 10px".toCss):

  span text "Select an image to overlay onto the editor preview."
  span text "The image will be stretched to fit the editor preview's"

  # Add a bonk themed label to the file input
  # it can handle the events for the input
  # Hide the original file input so only the bonk themed label shows
  label(`for` = "kkleeEditorImageOverlayInput"):
    # Button is a noop - the <input> should handle it
    span bonkButton("Choose image", proc = return)
  input(
    `type` = "file",
    id = "kkleeEditorImageOverlayInput",
    accept = "image/*",
    style = "display: none".toCss
  ):
    proc oninput(e: Event; n: VNode) =
      loadEditorImageOverlay(e)
    proc onclick(e: Event; n: VNode) =
      # This will reset the input's value to an empty string
      # so if the user picks another image with the same file name, oninput()
      # will be triggered and the image will be overlayed again
      n.value = ""

  if st.imageState == "error":
    span(style = "color: rgb(204, 68, 68)".toCss):
      text "An error occurred"

  if st.imageState == "image":
    # Calling the function without any parameters will clear the image
    bonkButton("Clear image", proc () = loadEditorImageOverlay())

    # Opacity slider - Value from 0 to 1
    label(`for` = "kkleeEditorImageOverlayOpacity"):
      span text "Overlay opacity:"
    input(
      id = "kkleeEditorImageOverlayOpacity",
      title = "Overlay opacity",
      class = "compactSlider compactSlider_classic",
      `type` = "range",
      min = "0",
      max = "1",
      step = "0.05"
    ):
      proc oninput(e: Event; n: VNode) =
        st.opacity = parseFloat($n.value)
        updateSpriteSettings()
    span text &"Image res.: {st.ogW.int}x{st.ogH.int}"
 
    span:
      text "X:"
      bonkInput(st.x, parseFloat, updateSpriteSettings, niceFormatFloat)
    span:
      text "Y:"
      bonkInput(st.y, parseFloat, updateSpriteSettings, niceFormatFloat)
    span:
      text "Width:"
      bonkInput(st.w, parseFloat, updateSpriteSettings, niceFormatFloat)
    span:
      text "Height:"
      bonkInput(st.h, parseFloat, updateSpriteSettings, niceFormatFloat)
