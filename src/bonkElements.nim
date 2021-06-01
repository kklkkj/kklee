import strformat, dom, sugar, options, strutils
import karax / [kbase, karax, karaxdsl, vdom, vstyles]

proc bonkButton*(label: string; onClick: proc; disabled: bool = false): VNode =
  let disabledClass = if disabled: "brownButtonDisabled" else: ""
  buildHtml(tdiv(
    class = &"brownButton brownButton_classic buttonShadow {disabledClass}")
  ):
    text label
    if not disabled:
      proc onClick = onClick()


proc defaultFormat[T](v: T) = $v
proc niceFormatFloat*(f: float): string = f.formatFloat(precision = -1)

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

proc prsFLimited*(s: string): float =
  result = s.parseFloat
  if result notin -1e6..1e6: raise newException(ValueError, "prsFLimited")

proc prsFLimitedPostive*(s: string): float =
  result = s.prsFLimited
  if result < 0.0: raise newException(ValueError, "prsFLimitedPostive")
