import
  std/[dom, strformat],
  pkg/karax/[karaxdsl, vdom, vstyles],
  kkleeApi

proc mapSizeInfo*: VNode = buildHtml tdiv(
    style = "display: flex; flex-flow: column; font-size: 16px".toCss):
  span text &"Shapes: {moph.fixtures.len}/1000"
  span text &"Platforms: {moph.bodies.len}/300"
  span text &"Joints: {moph.joints.len}/100"
  span text &"Spawns: {mapObject.spawns.len}/100"
  span text &"Capzones: {mapObject.capZones.len}/50"
  span text &"Data limit: {dataLimitInfo()}"
