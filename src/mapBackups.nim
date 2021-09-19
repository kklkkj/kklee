import
  std/[dom, sugar],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi

proc mapBackupLoader*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 15px".toCss):
  proc backupOption(b: MapBackupObject): VNode = buildHtml li(
    style = "margin-top: 5px; background-color: peru".toCss
  ):
    text b.getBackupLabel()
    proc onClick =
      b.loadBackup()
      saveToUndoHistory()
      updateLeftBox()
      updateModeDropdown()
      updateRenderer(true)
      updateRightBoxBody(-1)
      updateWarnings()

  ul(style = "padding-left: 15px; font-size: 13px".toCss):
    for i in countdown(kkleeApi.mapBackups.high, 0):
      backupOption(kkleeApi.mapBackups[i])
