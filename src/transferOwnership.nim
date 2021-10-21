import
  std/[dom, strformat],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

template m: untyped = mapObject.m

proc transferOwnership*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  if m.a != m.rxa and m.rxa != "":
    text (
      "Failed to verify that you are the original author. You must save this " &
      "map onto your account first.")
  else:
    var username {.global.} = ""
    select:
      option(disabled = "true", hidden = "true", selected = "true", value = ""):
        text "-"
      for c in mapObject.m.cr:
        option text c
      proc onInput(e: Event; n: VNode) =
        username = $e.target.OptionElement.value
    bonkButton(&"Transfer ownership to {username}", proc =
      if username.cstring notin m.cr:
        username = ""
        return
      m.a = cstring username
      m.rxa = ""
      m.rxdb = 1
      m.rxid = 0
      m.rxn = ""
      m.cr = @[]
    , username == "")

