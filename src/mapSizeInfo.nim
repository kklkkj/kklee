import
  std/[dom, strformat],
  pkg/karax/[karaxdsl, vdom, vstyles],
  kkleeApi

proc mapSizeInfo*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 15px".toCss):
  ul:
    li text &"Shapes: {moph.fixtures.len}/1000"
    li text &"Platforms: {moph.bodies.len}/300"
    li text &"Joints: {moph.joints.len}/100"
    li text &"Spawns: {mapObject.spawns.len}/100"
    li text &"Capzones: {mapObject.capZones.len}/50"
    li text &"Data limit: {dataLimitInfo()}"
