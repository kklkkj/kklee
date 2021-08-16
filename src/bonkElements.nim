import
  std/[strformat, dom, sugar, options, strutils],
  pkg/karax/[karax, karaxdsl, vdom, vstyles]

proc bonkButton*(label: string; onClick: proc; disabled: bool = false): VNode =
  let disabledClass = if disabled: "brownButtonDisabled" else: ""
  buildHtml(tdiv(
    class = &"brownButton brownButton_classic buttonShadow {disabledClass}")
  ):
    text label
    if not disabled:
      proc onClick = onClick()


func defaultFormat*[T](v: T) = $v
func niceFormatFloat*(f: float): string = f.formatFloat(precision = -1)

# Note: there is bonkInputWide in shapeGenerator...
proc bonkInput*[T](variable: var T; parser: string -> T;
    afterInput: proc(): void = nil; stringify: T ->
        string): VNode =
  buildHtml:
    input(class = "mapeditor_field mapeditor_field_spacing_bodge fieldShadow",
        value = variable.stringify, style = "width: 50px".toCss):
      proc onInput(e: Event; n: VNode) =
        try:
          variable = parser $n.value
          e.target.style.color = ""
          if not afterInput.isNil:
            afterInput()
        except CatchableError:
          e.target.style.color = "rgb(204, 68, 68)"

proc colourInput*(variable: var int; afterInput: proc(): void = nil): VNode =
  buildHtml:
    input(`type` = "color"):
      proc onInput(e: Event; n: VNode) =
        let v = $n.value
        variable = v[1..^1].parseHexInt
        if not afterInput.isNil:
          afterInput()

proc checkbox*(variable: var bool; afterInput: proc(): void = nil): VNode =
  let colour =
    if variable: "#59b0d6"
    else: "#586e77"
  buildHtml:
    tdiv(style = ("width: 10px; height: 10px; margin: 3px; " &
      "border: 2px solid #111111; background-color: {colour}").fmt.toCss
    ):
      proc onClick = variable = not variable

func prsFLimited*(s: string): float =
  result = s.parseFloat
  if result notin -1e6..1e6: raise newException(ValueError, "prsFLimited")

func prsFLimitedPositive*(s: string): float =
  result = s.prsFLimited
  if result < 0.0: raise newException(ValueError, "prsFLimitedPostive")

type boolPropValue* = enum
  tfsSame, tfsTrue, tfsFalse

proc tfsCheckbox*(inp: var boolPropValue): VNode =
  let colour = case inp
    of tfsTrue: "#59d65e"
    of tfsFalse: "#d65959"
    of tfsSame: "#d6bd59"
  return buildHtml tdiv(style = ("width: 10px; height: 10px; margin: 3px; " &
    "border: 2px solid #111111; background-color: {colour}").fmt.toCss
  ):
    proc onClick =
      inp = case inp
        of tfsSame: tfsTrue
        of tfsTrue: tfsFalse
        of tfsFalse: tfsSame
