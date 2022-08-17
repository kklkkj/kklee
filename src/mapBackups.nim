import
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi

proc mapBackupLoader*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 13px".toCss):
  proc backupOption(b: MapBackupObject): VNode = buildHtml tdiv(
    style = "padding: 5px 0px; border-top: 2px grey solid".toCss
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

  for i in countdown(kkleeApi.mapBackups.high, 0):
    backupOption(kkleeApi.mapBackups[i])

  proc onMouseEnter =
    setEditorExplanation(
      "[kklee]\nMaps are automatically backed up to your browser's storage."
    )
