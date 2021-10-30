import
  pkg/karax/[vdom, kdom, vstyles, karax, karaxdsl, jstrutils],
  kkleeApi, bonkElements

proc editorImageOverlay*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px; row-gap: 10px".toCss):
  
  span text ("Select an image to overlay onto the editor preview.")
  span text ("The image will be stretched to fit the editor preview's")

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
    style = "display: none".toCss):
      proc oninput(e: Event; n: VNode) =
        loadEditorImageOverlay(e)
      proc onclick(e: Event; n: VNode) =
        # This will reset the input's value to an empty string
        # so if the user picks another image with the same file name, oninput()
        # will be triggered and the image will be overlayed again
        n.value = ""

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
    step = "0.05"):
      proc oninput(e: Event; n: VNode) =
        editorImageOverlayOpacity = parseFloat($n.value)
        drawEditorImageOverlay()