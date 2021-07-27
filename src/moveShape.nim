import
  std/[strformat, dom, sequtils],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  kkleeApi, bonkElements

proc moveShape*(msfx: var MapFixture; msb: var MapBody): VNode =
  buildHtml(tdiv):
    select(style = "margin-bottom: 10px".toCss):
      for bi in mapObject.physics.bro:
        option:
          text bi.getBody.n

      proc onInput(e: Event; n: VNode) =
        msb =
          mapObject.physics.bro[e.target.OptionElement.selectedIndex].getBody
      proc onMouseEnter(e: Event; n: VNode) =
        msb =
          mapObject.physics.bro[e.target.OptionElement.selectedIndex].getBody

    bonkButton("Move", proc =
      let fxId = mapObject.physics.fixtures.find(msfx)
      if fxId == -1: return
      for b in mapObject.physics.bodies:
        b.fx.keepItIf it != fxId
      msb.fx.add fxId
      setCurrentBody(mapObject.physics.bodies.find msb)
      updateLeftBox()
      updateRightBoxBody(fxId)
      saveToUndoHistory()

    , msb.isNil)
