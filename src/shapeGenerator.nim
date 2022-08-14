import
  std/[dom, strutils, math, sugar, strformat],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr,
  kkleeApi, bonkElements, shapeMultiSelect, colours

type
  ShapeGeneratorType = enum
    sgsEllipse = "Polygon/Ellipse/Spiral", sgsSine = "Sine wave",
    sgsLinearGradient = "Linear gradient",
    sgsRadialGradient = "Radial gradient", sgsEquation = "Parametric equation"

func dtr(f: float): float = f.degToRad

func safeFloat(n: float): float =
  if n.isNaN:
    0.0
  else:
    n.clamp(-1e6, 1e6)
func safePos(p: MapPosition): MapPosition =
  [p.x.safeFloat, p.y.safeFloat].MapPosition

type LinesShapeSettings = ref object
  body: MapBody
  x, y, angle: float
  colour: int
  precision: int
  noPhysics: bool
  rectHeight: float

proc genLinesShape(settings: LinesShapeSettings, getPos: float -> MapPosition) =
  proc getPosAdj(x: float): MapPosition =
    let sa = settings.angle.dtr
    var r = getPos(x)
    r = r.rotatePoint(sa)
    r.x += settings.x
    r.y += settings.y
    return r

  for n in 0..settings.precision-1:
    let
      p1 = getPosAdj(n / settings.precision).safePos
      p2 = getPosAdj((n + 1) / settings.precision).safePos

    let shape = MapShape(
      stype: "bx",
      c: [(p1.x + p2.x) / 2, (p1.y + p2.y) / 2].MapPosition,
      bxH: settings.rectHeight,
      bxW: sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2),
      a: arctan((p1.y - p2.y) / (p1.x - p2.x)).safeFloat
    )
    moph.shapes.add shape

    let fixture = MapFixture(n: cstring &"rect{n}", de: jsNull, re: jsNull,
      fr: jsNull, f: settings.colour, sh: moph.shapes.high, np: settings.noPhysics
    )
    moph.fixtures.add fixture
    settings.body.fx.add moph.fixtures.high

type EllipseSettings = ref object
  linesShape: LinesShapeSettings
  widthRadius, heightRadius, angleStart, angleEnd, spiralStart: float
  hollow: bool

proc generateEllipse(settings: EllipseSettings): int =
  if settings.hollow:
    proc getPos(x: float): MapPosition =
      let
        a = settings.angleEnd.dtr -
          (settings.angleEnd.dtr - settings.angleStart.dtr) * x
        s = settings.spiralStart + (1 - settings.spiralStart) * x
      return [
        settings.widthRadius * sin(a) * s,
        settings.heightRadius * cos(a) * s
      ]

    genLinesShape(settings.linesShape, getPos)

    result = settings.linesShape.precision

  else:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: settings.linesShape.angle.dtr,
      c: [settings.linesShape.x, settings.linesShape.y].MapPosition
    )

    for n in 0..settings.linesShape.precision:
      let a = settings.angleEnd.dtr -
        (settings.angleEnd.dtr - settings.angleStart.dtr) /
        settings.linesShape.precision.float * n.float
      shape.poV.add [
        sin(a) * settings.widthRadius, cos(a) * settings.heightRadius
      ].MapPosition
    # Delete superfluous shape
    if abs(settings.angleEnd - settings.angleStart) == 360:
      shape.poV.delete shape.poV.high

    moph.shapes.add shape
    let fixture = MapFixture(n: "ellipse", de: jsNull, re: jsNull, fr: jsNull,
        f: settings.linesShape.colour, sh: moph.shapes.high,
        np: settings.linesShape.noPhysics
    )
    moph.fixtures.add fixture
    settings.linesShape.body.fx.add moph.fixtures.high
    result = 1

type SineSettings = ref object
  linesShape: LinesShapeSettings
  width, height, oscillations, start: float

proc generateSine(settings: SineSettings): int =
  proc getPos(x: float): MapPosition =
    let
      sx = x * 2 * PI * settings.oscillations + settings.start
      asx = sx + sin(2 * sx) / 2.7
    return [
      settings.width * (asx - settings.start) / settings.oscillations / 2 / PI,
      sin(asx) * settings.height
    ]

  genLinesShape(settings.linesShape, getPos)

  result = settings.linesShape.precision

type EquationSettings = ref object
  linesShape: LinesShapeSettings
  inputX, inputY: string
  polygon: bool

proc generateEquation(settings: EquationSettings): int =
  proc getPos(x: float): MapPosition =
    let ev = newEvaluator()
    ev.addVar("t", x)
    return [ev.eval settings.inputX, ev.eval settings.inputY]

  if settings.polygon:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: settings.linesShape.angle.dtr,
      c: [settings.linesShape.x, settings.linesShape.y].MapPosition
    )

    for n in 0..settings.linesShape.precision:
      let
        ev = newEvaluator()
        x = n / settings.linesShape.precision * 0.999999999
      ev.addVar("t", x)
      shape.poV.add [
        ev.eval settings.inputX, ev.eval settings.inputY
      ].MapPosition

    moph.shapes.add shape
    let fixture = MapFixture(n: "equation", de: jsNull, re: jsNull, fr: jsNull,
        f: settings.linesShape.colour, sh: moph.shapes.high,
        np: settings.linesShape.noPhysics
    )
    moph.fixtures.add fixture
    settings.linesShape.body.fx.add moph.fixtures.high
    return 1
  else:
    genLinesShape(settings.linesShape, getPos)
    return settings.linesShape.precision

type
  GradientSettings = ref object
    body: MapBody
    x, y: float
    precision: int
    # Linear if true, radial if false. I should improve this code later.
    linear: bool
    rectWidth, rectHeight, rectAngle: float
    circleRadius1, circleRadius2: float
    gradient: MultiColourGradient

proc generateGradient(settings: GradientSettings): int =
  for i in 0..settings.precision-1:
    var shape: MapShape

    if settings.linear:
      shape = MapShape(
        stype: "bx", bxW: settings.rectWidth / settings.precision.float,
        bxH: settings.rectHeight,
        a: settings.rectAngle.dtr,
        c: [
            settings.rectWidth * i.float / settings.precision.float -
              settings.rectWidth / 2.0 + settings.rectWidth /
              settings.precision.float / 2,
            0
          ].MapPosition
        )

      block:
        let sa = settings.rectAngle.dtr
        shape.c = shape.c.rotatePoint(sa)
        shape.c.x += settings.x
        shape.c.y += settings.y
    else:
      let crm = i.float / (settings.precision.float - 1)
      shape = MapShape(
        stype: "ci", ciR: settings.circleRadius1 * crm +
          settings.circleRadius2 * (1.0 - crm),
        c: [settings.x, settings.y]
      )

    moph.shapes.add shape
    let
      colour = getColourAt(
        settings.gradient, GradientPos(i / (settings.precision - 1))).int
      fixture = MapFixture(n: cstring &"gradient{i}", de: jsNull, re: jsNull,
        fr: jsNull, f: colour, sh: moph.shapes.high, np: true)
    moph.fixtures.add fixture
    settings.body.fx.add moph.fixtures.high
  return settings.precision

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    tdiv(style = "font-size:12px".toCss):
      text &"Shapes in platform: {body.fx.len}/100"
    var generateProc: void -> int
    
    var
      previewShapesCount {.global.}: int
      selecting {.global.}: bool = true
      previousBody {.global.}: MapBody
      generatorType {.global.}: ShapeGeneratorType
      multiSelectShapes {.global.}: bool
    if body != previousBody:
      selecting = true
    previousBody = body

    let
      generate = proc =
        previewShapesCount = generateProc()
        updateRenderer(true)
        updateRightBoxBody(-1)
      remove = proc =
        body.fx.setLen body.fx.len - previewShapesCount
        moph.fixtures.setLen moph.fixtures.len - previewShapesCount
        moph.shapes.setLen moph.shapes.len - previewShapesCount
        previewShapesCount = 0
        updateRenderer(true)
        updateRightBoxBody(-1)
      update = proc =
        remove()
        generate()

    template pbi(va): untyped =
      bonkInput(va, prsFLimited, update, niceFormatFloat)

    if selecting:
      template sb(s): untyped =
        bonkButton($s, proc =
          selecting = false
          generatorType = s
        )
      sb sgsEllipse
      sb sgsSine
      sb sgsLinearGradient
      sb sgsRadialGradient
      sb sgsEquation

    else:
      bonkButton("Back", proc =
        selecting = true
        remove()
      )

      template precisionInput(va): untyped =
        bonkInput(va, proc(s: string): int =
          let res = s.parseInt
          if res notin 1..999:
            raise newException(ValueError, "prec notin 1..999")
          res
        , update, i => $i)

      prop("Multi-select", checkbox(multiSelectShapes))

      case generatorType
      of sgsEllipse:
        var settings {.global.} = EllipseSettings(
          linesShape: LinesShapeSettings(
            x: 0, y: 0, angle: 0,
            colour: 0xffffff, precision: 20, noPhysics: false, rectHeight: 1
          ),
          widthRadius: 100, heightRadius: 100, angleStart: 0, angleEnd: 360,
          spiralStart: 1, hollow: false
        )
        settings.linesShape.body = body
        
        generateProc = () => generateEllipse(settings)
        prop("x", pbi settings.linesShape.x)
        prop("y", pbi settings.linesShape.y)
        prop("Colour", colourInput(settings.linesShape.colour))
        prop("No physics", checkbox(settings.linesShape.noPhysics))
        prop("Angle", pbi settings.linesShape.angle)
        prop("Shapes/vertices", precisionInput settings.linesShape.precision)
        prop("Width radius", pbi settings.widthRadius)
        prop("Height radius", pbi settings.heightRadius)
        prop("Angle start", pbi settings.angleStart)
        prop("Angle end", pbi settings.angleEnd)
        prop("Hollow", checkbox(settings.hollow))

        if settings.hollow:
          prop("Spiral start", pbi settings.spiralStart)
          prop("Rect height", pbi settings.linesShape.rectHeight)

      of sgsSine:
        var settings {.global.} = SineSettings(
          linesShape: LinesShapeSettings(
            x: 0, y: 0, angle: 0,
            colour: 0xffffff, precision: 20, noPhysics: false, rectHeight: 1
          ),
          width: 300, height: 75, oscillations: 2, start: 0
        )
        settings.linesShape.body = body

        generateProc = () => generateSine(settings)
        prop("x", pbi settings.linesShape.x)
        prop("y", pbi settings.linesShape.y)
        prop("Colour", colourInput(settings.linesShape.colour))
        prop("Angle", pbi settings.linesShape.angle)
        prop("Shapes", precisionInput settings.linesShape.precision)
        prop("Width", pbi settings.width)
        prop("Height", pbi settings.height)
        prop("Oscillations", pbi settings.oscillations)
        prop("Rect height", pbi settings.linesShape.rectHeight)
      of sgsLinearGradient, sgsRadialGradient:
        var settings {.global.} = GradientSettings(
          x: 0, y: 0, precision: 16,
          rectWidth: 150, rectHeight: 150, rectAngle: 0,
          circleRadius1: 30, circleRadius2: 150,
          gradient: defaultMultiColourGradient()
        )
        settings.body = body

        generateProc = () => generateGradient(settings)
        prop("x", pbi settings.x)
        prop("y", pbi settings.y)
        gradientProp(settings.gradient)
        prop("Shapes", precisionInput settings.precision)
        case generatorType
        of sgsLinearGradient:
          settings.linear = true
          prop("Angle", pbi settings.rectAngle)
          prop("Width", pbi settings.rectWidth)
          prop("Height", pbi settings.rectHeight)
        of sgsRadialGradient:
          settings.linear = false
          prop("Inner circle radius", pbi settings.circleRadius1)
          prop("Outer circle radius", pbi settings.circleRadius2)
        else: discard

      of sgsEquation:
        var settings {.global.} = EquationSettings(
          linesShape: LinesShapeSettings(
            x: 0, y: 0, angle: 0,
            colour: 0xffffff, precision: 20, noPhysics: false, rectHeight: 1
          ),
          inputX: "(t-0.5)*100", inputY: "-((t*2-1)^2)*100",
          polygon: false
        )
        settings.linesShape.body = body
        
        generateProc = () => generateEquation(settings)
        prop("x", pbi settings.linesShape.x)
        prop("y", pbi settings.linesShape.y)
        prop("Colour", colourInput(settings.linesShape.colour))
        prop("Angle", pbi settings.linesShape.angle)
        prop("Shapes", precisionInput settings.linesShape.precision)
        prop("Rect height", pbi settings.linesShape.rectHeight)
        prop("Polygon", checkbox(settings.polygon))

        # bonkInput but with a width of 150px
        proc bonkInputWide[T](variable: var T; parser: string -> T;
            afterInput: proc(): void = nil; stringify: T ->
                string): VNode =
          buildHtml:
            input(class =
              "mapeditor_field mapeditor_field_spacing_bodge fieldShadow",
              value = cstring variable.stringify, style = "width: 150px".toCss
            ):
              proc onInput(e: Event; n: VNode) =
                try:
                  variable = parser $n.value
                  e.target.style.color = ""
                  if not afterInput.isNil:
                    afterInput()
                except CatchableError:
                  e.target.style.color = "var(--kkleeErrorColour)"
        template eqInp(va): untyped =
          bonkInputWide(va, proc(s: string): string =
            # Check for error
            let ev = newEvaluator()
            ev.addVar("t", 0.0)
            discard ev.eval s
            return s
          , update, s=>s)
        prop("X", eqInp(settings.inputX))
        prop("Y", eqInp(settings.inputY))

        ul(style = "font-size:11px; padding-left: 10px; margin: 3px".toCss):
          li text (
            "It is recommended that you experiment with equations on " &
            "a graphing calculator like Desmos before using them here")


      bonkButton(&"Save {$generatorType}", proc =
        update()
        if multiSelectShapes:
          shapeMultiSelectSwitchPlatform()
          for fxId in moph.fixtures.len-previewShapesCount..moph.fixtures.high:
            selectedFixtures.add fxId.getFx
          shapeMultiSelectElementBorders()
        previewShapesCount = 0
        saveToUndoHistory()
      )

      proc onMouseEnter = update()
      proc onMouseLeave = remove()
