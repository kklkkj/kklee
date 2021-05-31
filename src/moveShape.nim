import strformat, dom, sugar, sequtils
import karax / [kbase, karax, karaxdsl, vdom, vstyles]
import kkleeApi, bonkElements

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
      let fxi = mapObject.physics.fixtures.find(msfx)
      if fxi == -1: return
      for b in mapObject.physics.bodies:
        b.fx.keepIf i => i != fxi
      msb.fx.add fxi
      setCurrentBody(mapObject.physics.bodies.find msb)
      updateLeftBox()
      updateRightBoxBody(fxi)

    , msb.isNil)
