# kklee guide

## Minor features

- The chat is visible in the editor.
- You can use your browser's colour picker to choose colours (this allows you to
  specify exact colour values).
- When you try to exit bonk.io, the page will prompt you to confirm that you
  want to close the page.
- Rectangles can be quickly converted to polygons.
- You can quickly open a shape's capture zone settings.

## Keyboard shortcuts

- Save map: `Ctrl + S`
- Start/stop preview: `Space`
- Play: `Shift + Space`,
- Exit game: `Shift + Esc`
- When editing a number field, you can use up/down arrows to increase/decrease
  the value. For example, when you are editing a shape's X coordinate, pressing
  `up` will increase the value by 10 and `down` will decrease it.

  Shortcut modifiers for changing amount:

  - Just Arrow: `10`
  - Shift + Arrow: `1`
  - Ctrl + Arrow: `100`
  - Ctrl + Shift + Arrow: `0.1`

- Arrow to pan the editor preview when it is focused.

  Shortcut modifiers for changing pan amount:

  - Just Arrow: `50`
  - Shift + Arrow: `25`
  - Ctrl + Arrow: `150`
  - Ctrl + Shift + Arrow: `10`

## Shape generator

You can access the shape generator by pressing "Generate shape" at the top of
the shapes list. It can generate regular polygons/ellipses/spirals, sine waves,
linear gradients, radial gradients and custom parametric equations.

## Vertex editor

You can manually edit a polygon's vertices by opening the vertex editor in the
shape's properties.

Vertices that cause the polygon to be concave will be outlined in red.

Make sure that vertices are specified in a clockwise order, otherwise the
polygon will be counted as concave.

There are also some additional features such as:

- Rounding corners
- Splitting a conave polygon into multiple convex polygons
- (BUGGY) merging of multiple no physics shapes with the same colour into one
  polygon.

## Multiselect shapes and platforms

You can select multiple shapes or platforms and mass-modify their properties.

To select platforms, shift + click the platform's name in the platforms list.

To select shapes, shift + click the shape's name textbox.

Use the "apply" button to apply changes.

### Selecting shapes in collection

The "Include shapes from" option changes what set of shapes the "Select all",
etc buttons will act on.

### Mathematical expression evaluation in multiselect

[(More info about mathematical expression evaluation)](#mathematical-expression-evaluator)

`x` is equal to the property's current value.

Example: `x+50` will increase the value by 50.

(Note: "item" will refer to the shape/platform)

`i` is equal to the items index in the list of selected items. This
is indicated by the blue number next to the item. The 1st selected item has
i=0, 2nd has i=1, etc.

Example: setting the X position in shape multiselect to `i*50` will set the 1st
shape's X to `0`, 2nd shape's X to `50`, 3rd shape's X to `100`, etc.

### Name property

In the name property, anything between a pair of `||`s will be treated as a
mathematical expression to evaluate. The `i` variable is available but `x`
isn't.

### Checkboxes

- Yellow (-) = unchanged
- Green (tick) = enable
- Red (X) = disable

### Copy and pasting in platform multiselect

If you use `Instant copy&paste`, joints on the pasted platforms will be attached
to the original platforms, not the new pasted platforms.

For example, if you have platforms `A1` and `B1` where `A1` has a joint attached
to `B1`, and you `instant copy&paste` both platforms to produce `A2` and `B2`,
`A2`'s joint will be attached to the original `B1`, not the new `B2`.

If you use the separate `copy` and `paste` buttons, `A2`'s joint will be
attached to the new `B2`.

## Automatic backups

kklee automatically backs up your maps to your browser's offline storage.
To access your backups, go to map settings (gear icon) and click
"Load map backup".

kklee will use a maximum of 1 MB of storage to store backups. Older backups are
deleted once that limit is reached.

## Automatic update checking

kklee can automatically check if new versions of itself are available. To enable
this option, go to map settings (gear icon) and then "kklee settings".

This will send a HTTP request to GitHub.com when the page is loaded at a maximum
of once per hour.

## Image overlay

You can overlay an image over the map preview to help you trace it. This feature
can be access in map settings (gear icon) -> "Image overlay".

## Transfer map ownership

You can transfer ownership of your map to another user to let them save the map
without the map being marked as an edit. This will not transfer the map's likes
or creation date.

You can do this if your account's username is the author or `Original author` of
the map. You can transfer ownership to yourself or a user in the `Contributors`
list.

## Change speed of map preview

A slider is added next to the play preview button at the top that allows you to
change the speed of the preview. The vertical bar indicates normal speed.

## Evaluate maths in number fields

When editing number fields, you can quickly calculate mathematical expressions
[(more info)](#mathematical-expression-evaluator) with `Shift + Enter`.

For example, entering `100+30*2` into X position field and pressing
`Shift + Enter` will change the value to `160`.

## Mathematical expression evaluator

Supported operators include `+`, `-`, `/`, `*`, `%`, `^`

Predefined constants: `pi`, `tau`, `e`

<details>
<summary>Implemented functions:</summary>
**Note:** angles are in radians

- `rand()` - a random number in the range 0 to less than 1
- `abs(x)` - the absolute value of `x`
- `acos(x)` or `arccos(x)` - the arccosine (in radians) of `x`
- `asin(x)` or `arcsin(x)` - the arcsine (in radians) of `x`
- `atan(x)` or `arctan(x)` or `arctg(x)` - the arctangent (in radians) of `x`
- `atan2(x, y)` or `arctan2(x, y)` - the arctangent of the \
  quotient from provided `x` and `y`
- `ceil(x)` - the smallest integer greater than or equal to `x`
- `cos(x)` - the cosine of `x`
- `cosh(x)` - the hyperbolic cosine of `x`
- `deg(x)` - converts `x` in radians to degrees
- `exp(x)` - the exponential function of `x`
- `sgn(x)` - the sign of `x`
- `sqrt(x)` - the square root of `x`
- `sum(x, y, z, ...)` - sum of all passed arguments
- `fac(x)` - the factorial of `x`
- `floor(x)` - the largest integer not greater than `x`
- `ln(x)` - the natural log of `x`
- `log(x)` or `log10(x)` - the common logarithm (base 10) of `x`
- `log2(x)` - the binary logarithm (base 2) of `x`
- `max(x, y, z, ...)` - biggest argument from any number of arguments
- `min(x, y, z, ...)` - smallest argument from any number of arguments
- `ncr(x, y)` or `binom(x, y)` - the the number of ways a sample of \
  `y` elements can be obtained from a larger set of `x` distinguishable \
  objects where order does not matter and repetitions are not allowed
- `npr(x, y)` - the number of ways of obtaining an ordered subset of `y` \
  elements from a set of `x` elements
- `rad(x)` - converts `x` in degrees to radians
- `pow(x, y)` - the `x` to the `y` power
- `sin(x)` - the sine of `x`
- `sinh(x)` - the hyperbolic sine of `x`
- `tg(x)` or `tan(x)` - the tangent of `x`
- `tanh(x)` - the hyperbolic tangent of `x`
</details>
