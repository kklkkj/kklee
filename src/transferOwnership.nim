import
  std/[dom, strformat],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

template m: untyped = mapObject.m

proc transferUsernames: seq[cstring] =
  # I can't use the add proc inside builtHtml..?
  var transferUsernames = m.cr
  if m.a notin transferUsernames: transferUsernames.add m.a
  if m.rxa notin transferUsernames and m.rxa != "": transferUsernames.add m.rxa
  return transferUsernames

proc transferOwnership*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column".toCss):
  if not canTransferOwnership():
    text "You must be the original author to transfer ownership."
  else:
    var username {.global.} = ""

    span text "Map contributors:"
    select:
      option(disabled = "true", hidden = "true", selected = "true", value = ""):
        text "-"
      for c in transferUsernames():
        option text c
      proc onInput(e: Event; n: VNode) =
        username = $e.target.OptionElement.value
    bonkButton(&"Transfer ownership", proc =
      if username.cstring notin transferUsernames():
        username = ""
        return
      m.a = cstring username
      m.rxa = ""
      m.rxdb = 1
      m.rxid = 0
      m.rxn = ""
      m.cr = @[]
      username = ""
    , username == "")

