import strformat, dom, algorithm, sugar, strutils, options, math, sequtils
import karax / [kbase, karax, karaxdsl, vdom, vstyles]

proc bonkButton*(label: string; onClick: proc; disabled: bool = false): VNode =
  let disabledClass = if disabled: "brownButtonDisabled" else: ""
  buildHtml(tdiv(
    class = &"brownButton brownButton_classic buttonShadow {disabledClass}")
  ):
    text label
    if not disabled:
      proc onClick = onClick()

proc bonkInput*[T](variable: var T; parser: string -> T;
    afterInput: proc(): void = nil): VNode =
  buildHtml:
    input(class = "mapeditor_field mapeditor_field_spacing_bodge fieldShadow",
    value = $variable):
      proc onInput(e: Event; n: VNode) =
        try:
          variable = parser $n.value
          e.target.style.color = ""
          if not afterInput.isNil:
            afterInput()
        except CatchableError:
          e.target.style.color = "rgb(204, 68, 68)"
