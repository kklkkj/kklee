import
  pkg/karax/[karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

proc kkleeSettings*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  var updateChecksEnabled {.global.} = areUpdateChecksEnabled()
  prop((
    "Automatically check for kklee updates when bonk.io loads " &
    "(at a maximum of once per hour). This sends a HTTP request to GitHub.com."
    ),
    checkbox(updateChecksEnabled, proc =
      setEnableUpdateChecks(updateChecksEnabled)
    )
  )
