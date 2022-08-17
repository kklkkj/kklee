import
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

proc kkleeSettings*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  tdiv:
    proc onMouseEnter =
      setEditorExplanation(
        "[kklee]\nAutomatically check for kklee updates when bonk.io loads " &
        "(at a maximum of once per hour). " &
        "This sends a HTTP request to GitHub.com."
      )
    var updateChecksEnabled {.global.} = areUpdateChecksEnabled()
    prop("Automatic update checks", checkbox(updateChecksEnabled, proc =
      setEnableUpdateChecks(updateChecksEnabled)
    ))
