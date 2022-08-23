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
  GeneratedShapes = seq[tuple[shape: MapShape, fixture: MapFixture]]

func dtr(f: float): float = f.degToRad

func safeFloat(n: float): float =
  if n.isNaN:
    0.0
  else:
    n.clamp(-1e6, 1e6)
func safePos(p: MapPosition): MapPosition =
  [p.x.safeFloat, p.y.safeFloat].MapPosition

type LinesShapeSettings = ref object
  colour: int
  precision: int
  rectHeight: float

proc genLinesShape(
  settings: LinesShapeSettings, getPos: float -> MapPosition
): GeneratedShapes =
  for n in 0..settings.precision-1:
    let
      p1 = getPos(n / settings.precision).safePos
      p2 = getPos((n + 1) / settings.precision).safePos

    let shape = MapShape(
      stype: "bx",
      c: [(p1.x + p2.x) / 2, (p1.y + p2.y) / 2].MapPosition,
      bxH: settings.rectHeight,
      bxW: sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2),
      a: arctan((p1.y - p2.y) / (p1.x - p2.x)).safeFloat
    )

    let fixture = MapFixture(
      n: cstring &"rect{n}", de: jsNull, re: jsNull,
      fr: jsNull, f: settings.colour
    )
    result.add((shape, fixture))

type EllipseSettings = ref object
  linesShape: LinesShapeSettings
  widthRadius, heightRadius, angleStart, angleEnd, spiralStart: float
  hollow: bool

proc generateEllipse(settings: EllipseSettings): GeneratedShapes =
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

    return genLinesShape(settings.linesShape, getPos)
  else:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: 0,
      c: [0.0, 0.0].MapPosition
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

    let fixture = MapFixture(
      n: "ellipse", de: jsNull, re: jsNull, fr: jsNull,
      f: settings.linesShape.colour
    )
    return @[(shape, fixture)]

type SineSettings = ref object
  linesShape: LinesShapeSettings
  width, height, oscillations, start: float

proc generateSine(settings: SineSettings): GeneratedShapes =
  proc getPos(x: float): MapPosition =
    let
      sx = x * 2 * PI * settings.oscillations + settings.start
      asx = sx + sin(2 * sx) / 2.7
    return [
      settings.width * (asx - settings.start) / settings.oscillations / 2 / PI,
      sin(asx) * settings.height
    ]

  return genLinesShape(settings.linesShape, getPos)

type EquationSettings = ref object
  linesShape: LinesShapeSettings
  inputX, inputY: string
  polygon: bool

proc generateEquation(settings: EquationSettings): GeneratedShapes =
  proc getPos(x: float): MapPosition =
    let ev = newEvaluator()
    ev.addVar("t", x)
    return [ev.eval settings.inputX, ev.eval settings.inputY]

  if settings.polygon:
    let shape = MapShape(
      stype: "po", poS: 1.0, a: 0,
      c: [0.0, 0.0].MapPosition
    )

    for n in 0..settings.linesShape.precision:
      let
        ev = newEvaluator()
        x = n / settings.linesShape.precision * 0.999999999
      ev.addVar("t", x)
      shape.poV.add [
        ev.eval settings.inputX, ev.eval settings.inputY
      ].MapPosition

    let fixture = MapFixture(n: "equation", de: jsNull, re: jsNull, fr: jsNull,
        f: settings.linesShape.colour
    )
    return @[(shape, fixture)]
  else:
    return genLinesShape(settings.linesShape, getPos)

type
  GradientSettings = ref object
    precision: int
    # Linear if true, radial if false. I should improve this code later.
    linear: bool
    rectWidth, rectHeight: float
    circleRadius1, circleRadius2: float
    gradient: MultiColourGradient

proc generateGradient(settings: GradientSettings): GeneratedShapes =
  for i in 0..settings.precision-1:
    var shape: MapShape

    if settings.linear:
      shape = MapShape(
        stype: "bx", bxW: settings.rectWidth / settings.precision.float,
        bxH: settings.rectHeight,
        a: 0,
        c: [
            settings.rectWidth * i.float / settings.precision.float -
              settings.rectWidth / 2.0 + settings.rectWidth /
              settings.precision.float / 2,
            0
        ].MapPosition
      )
    else:
      let crm =
        if settings.precision == 1: 1.0
        else: i / (settings.precision - 1)
      shape = MapShape(
        stype: "ci", ciR: settings.circleRadius1 * crm +
          settings.circleRadius2 * (1.0 - crm),
        c: [0.0, 0.0].MapPosition
      )

    let
      colour = getColourAt(
        settings.gradient, GradientPos(
          if settings.precision == 1: 1.0
          else: i / (settings.precision - 1)
        )
      ).int
      fixture = MapFixture(
        n: cstring &"gradient{i}", de: jsNull, re: jsNull,
        fr: jsNull, f: colour
      )
    result.add((shape, fixture))

proc shapeGenerator*(body: MapBody): VNode =
  buildHtml(tdiv(style = "display: flex; flex-flow: column".toCss)):
    var
      inFocus {.global.}: bool
      generatedShapes {.global.}: GeneratedShapes
      generateProc: () -> GeneratedShapes
      selecting {.global.}: bool = true
      previousBody {.global.}: MapBody
      generatorType {.global.}: ShapeGeneratorType
      multiSelectShapes {.global.}: bool
      shapesX {.global.}, shapesY {.global.}, shapesAngle {.global.}: float
      shapesNoPhysics {.global.}: bool

    if body != previousBody:
      selecting = true
    previousBody = body

    let
      addShapesToMap = proc =
        if not inFocus:
          return
        for (shape, fixture) in generatedShapes:
          let
            shape = copyObject(shape)
            fixture = copyObject(fixture)
          shape.c = shape.c.rotatePoint(shapesAngle.dtr)
          shape.c.x += shapesX
          shape.c.y += shapesY
          shape.a += shapesAngle.dtr
          fixture.np = shapesNoPhysics

          moph.shapes.add shape
          fixture.sh = moph.shapes.high
          moph.fixtures.add fixture
          body.fx.add moph.fixtures.high

        updateRenderer(true)
        updateRightBoxBody(-1)
      remove = proc =
        if not inFocus:
          return
        # Remove shapes from map
        body.fx.setLen(body.fx.len - generatedShapes.len)
        moph.fixtures.setLen(moph.fixtures.len - generatedShapes.len)
        moph.shapes.setLen(moph.shapes.len - generatedShapes.len)
        updateRenderer(true)
        updateRightBoxBody(-1)
      updateWithoutRegenerating = proc =
        # Regeneration is not needed when X, Y, angle or no physics is changed
        remove()
        addShapesToMap()
      update = proc =
        remove()
        generatedShapes = generateProc()
        addShapesToMap()

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
        generatedShapes = @[]
      )

      template pbi(va): untyped =
        bonkInput(va, prsFLimited, update, niceFormatFloat)
      template pbiWithoutRegenerating(va): untyped =
        bonkInput(va, prsFLimited, updateWithoutRegenerating, niceFormatFloat)

      template precisionInput(va): untyped =
        bonkInput(va, proc(s: string): int =
          let res = s.parseInt
          if res notin 1..999:
            raise newException(ValueError, "prec notin 1..999")
          res
        , update, i => $i)

      prop("Multi-select", checkbox(multiSelectShapes))
      prop("x", pbiWithoutRegenerating shapesX)
      prop("y", pbiWithoutRegenerating shapesY)
      prop("Angle", pbiWithoutRegenerating shapesAngle)

      case generatorType
      of sgsEllipse:
        var settings {.global.} = EllipseSettings(
          linesShape: LinesShapeSettings(
            colour: 0xffffff, precision: 20, rectHeight: 1
          ),
          widthRadius: 100, heightRadius: 100, angleStart: 0, angleEnd: 360,
          spiralStart: 1, hollow: false
        )

        generateProc = () => generateEllipse(settings)
        prop("Colour", colourInput(settings.linesShape.colour, update))
        prop("Shapes/vertices", precisionInput settings.linesShape.precision)
        prop("Width radius", pbi settings.widthRadius)
        prop("Height radius", pbi settings.heightRadius)
        prop("Angle start", pbi settings.angleStart)
        prop("Angle end", pbi settings.angleEnd)
        prop("Hollow", checkbox(settings.hollow, update))

        if settings.hollow:
          prop("Spiral start", pbi settings.spiralStart)
          prop("Rect height", pbi settings.linesShape.rectHeight)

      of sgsSine:
        var settings {.global.} = SineSettings(
          linesShape: LinesShapeSettings(
            colour: 0xffffff, precision: 20, rectHeight: 1
          ),
          width: 300, height: 75, oscillations: 2, start: 0
        )

        generateProc = () => generateSine(settings)
        prop("Colour", colourInput(settings.linesShape.colour, update))
        prop("Shapes", precisionInput settings.linesShape.precision)
        prop("Width", pbi settings.width)
        prop("Height", pbi settings.height)
        prop("Oscillations", pbi settings.oscillations)
        prop("Rect height", pbi settings.linesShape.rectHeight)
      of sgsLinearGradient, sgsRadialGradient:
        var settings {.global.} = GradientSettings(
          precision: 16,
          rectWidth: 150, rectHeight: 150,
          circleRadius1: 30, circleRadius2: 150,
          gradient: defaultMultiColourGradient()
        )
        shapesNoPhysics = true

        generateProc = () => generateGradient(settings)
        gradientProp(settings.gradient, update)
        prop("Shapes", precisionInput settings.precision)
        case generatorType
        of sgsLinearGradient:
          settings.linear = true
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
            colour: 0xffffff, precision: 20, rectHeight: 1
          ),
          inputX: "(t-0.5)*100", inputY: "-((t*2-1)^2)*100",
          polygon: false
        )

        generateProc = () => generateEquation(settings)
        prop("Colour", colourInput(settings.linesShape.colour, update))
        prop("Shapes", precisionInput settings.linesShape.precision)
        prop("Rect height", pbi settings.linesShape.rectHeight)
        prop("Polygon", checkbox(settings.polygon, update))

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

      # Workaround to avoid errors from karax
      discard (proc: int =
        if generatedShapes.len == 0:
          update()
        1
      )()

      bonkButton(&"Save {$generatorType}", proc =
        updateWithoutRegenerating()
        if multiSelectShapes:
          shapeMultiSelectSwitchPlatform()
          for fxId in (
            (moph.fixtures.len - generatedShapes.len)..moph.fixtures.high
          ):
            selectedFixtures.add fxId.getFx
          shapeMultiSelectElementBorders()
        generatedShapes = @[]
        saveToUndoHistory()
        selecting = true
      )

    proc onMouseEnter =
      inFocus = true
      if not selecting:
        addShapesToMap()
    proc onMouseLeave =
      if not selecting:
        remove()
      inFocus = false
