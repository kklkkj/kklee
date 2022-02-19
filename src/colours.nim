import std/[math]

type
  Colour* = distinct int
  RGB = array[3, int]
  GradientPos* = range[0.0..1.0]
  EasingType* = enum
    easeNone = "None", easeInSine = "Sine in", easeOutSine = "Sine out",
    easeInOutSine = "Sine in out"
  MultiColourGradientColour* = tuple[colour: Colour; pos: GradientPos]
  MultiColourGradient* = object
    colours*: seq[MultiColourGradientColour]
    easing*: EasingType

func getRGB(colour: Colour): RGB =
  let colour = colour.int
  [colour shr 16 and 255, colour shr 8 and 255, colour and 255]

func rgbToColour(r: RGB): Colour =
  return Colour(r[0] shl 16 or r[1] shl 8 or r[2])

func calculateEase(pos: GradientPos; ease: EasingType): GradientPos =
  case ease
  of easeNone: pos
  of easeInSine: 1 - cos(pos * PI / 2)
  of easeOutSine: sin(pos * PI / 2)
  of easeInOutSine: -0.5 * (cos(pos * PI) - 1)

func getGradientColourAt*(
  colour1, colour2: Colour; pos: GradientPos; ease: EasingType
): Colour =
  let
    colour1 = getRGB(colour1)
    colour2 = getRGB(colour2)
    pos = calculateEase(pos, ease)
  var rc: array[3, int]
  for i in 0..2:
    rc[i] =
      int(colour1[i].float * (1.0 - pos) +
          colour2[i].float * pos)
  return rgbToColour(rc)

func getColourAt*(
  gradient: MultiColourGradient; pos: GradientPos
): Colour =
  var
    colour1 = Colour 0
    colour2 = Colour 0
    gradientPos = GradientPos 0.0
  for i in 0..gradient.colours.high:
    let c2 = gradient.colours[i]
    if c2.pos >= pos:
      if i == 0:
        return c2.colour
      let c1 = gradient.colours[i-1]
      colour2 = c2.colour
      colour1 = c1.colour
      gradientPos = (pos - c1.pos) / (c2.pos - c1.pos)
      break
    if i == gradient.colours.high:
      return c2.colour
  return getGradientColourAt(colour1, colour2, gradientPos, gradient.easing)

func defaultMultiColourGradient*: MultiColourGradient =
  MultiColourGradient(
    colours: @[
      (Colour 0x2222ff, GradientPos 0), (Colour 0xff2222, GradientPos 1.0)
    ],
    easing: easeNone
  )
