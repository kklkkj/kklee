import
  std/[strformat, dom, sugar, options, strutils],
  pkg/karax/[karax, karaxdsl, vdom, vstyles],
  pkg/mathexpr

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

func prsFLimited*(s: string): float =
  result = s.parseFloat
  if result notin -1e6..1e6: raise newException(ValueError, "prsFLimited")

func prsFLimitedPositive*(s: string): float =
  result = s.prsFLimited
  if result < 0.0: raise newException(ValueError, "prsFLimitedPostive")

type boolPropValue* = enum
  tfsSame, tfsTrue, tfsFalse

proc checkbox*(variable: var bool; afterInput: proc(): void = nil): VNode =
  let things =
    if variable: ("#59b0d6", "✔")
    else: ("#586e77", "")
  buildHtml tdiv(style = ("width: 12px; height: 12px; text-align: center; " &
    "border: 2px solid #111111; background-color: {things[0]}; margin: 3px;")
    .fmt.toCss
  ):
    span(style = ("color: black; font-size: 12px; text-align: center; " &
      "top: -2px; position: relative").toCss
    ):
      text things[1]
    proc onClick = variable = not variable

proc tfsCheckbox*(inp: var boolPropValue): VNode =
  let things = case inp
    of tfsTrue: ("#59d65e", "✔")
    of tfsFalse: ("#d65959", "✖")
    of tfsSame: ("#d6bd59", "━")
  buildHtml tdiv(style = ("width: 12px; height: 12px; text-align: center; " &
    "border: 2px solid #111111; background-color: {things[0]}; margin: 3px;")
    .fmt.toCss
  ):
    span(style = ("color: black; font-size: 12px; " &
      "top: -2px; position: relative").toCss
    ):
      text things[1]
    proc onClick =
      inp = case inp
        of tfsSame: tfsTrue
        of tfsTrue: tfsFalse
        of tfsFalse: tfsSame

func prop*(name: string; field: VNode; highlight = false): VNode =
  buildHtml: tdiv(style =
    "display:flex; flex-flow: row wrap; justify-content: space-between"
    .toCss):
    span(style = (
      if highlight: "color: blueviolet; font-weight: bold" else: ""
    ).toCss):
      text name
    field

func floatNop*(f: float): float = f

proc floatPropInput*(inp: var string): VNode =
  buildHtml: bonkInput(inp, proc(parserInput: string): string =
    let evtor = newEvaluator()
    evtor.addVars {"x": 0.0, "i": 0.0, "n": 0.0}
    discard evtor.eval parserInput
    return parserInput
  , nil, s=>s)

proc floatPropApplier*(inp: string; i: int; n: int; prop: float): float =
  let evtor = newEvaluator()
  evtor.addVars {"x": prop, "i": i.float, "n": n.float}
  result = evtor.eval(inp).clamp(-1e6, 1e6)
  if result.isNaN: result = 0

proc dropDownPropSelect*[T](
  inp: var Option[T];
  options: seq[tuple[label: string; value: T]]
): VNode =
  buildHtml:
    select(style = "width: 80px".toCss):
      if inp.isNone:
        option(selected = ""): text "Unchanged"
      else:
        option: text "Unchanged"

      for o in options:
        let selected = inp.isSome and inp.get == o[1]
        if selected:
          option(selected = ""): text o[0]
        else:
          option: text o[0]

      proc onInput(e: Event; n: VNode) =
        let i = e.target.OptionElement.selectedIndex
        inp =
          if i == 0: none T.typedesc
          else: some options[i - 1][1]
