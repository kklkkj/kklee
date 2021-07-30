# Changelog

## v0.10
- Removed the "move to platform" feature in multi-select
- Removed multi-duplicate and added option to specify how many times copied
  shapes should be pasted
- Changed multi-select angle unit from radians to degrees
- Added buttons to select or deselect all shapes
- Added option to automatically multi-select generated shapes
- Fixed a bug in multi-select that caused kklee to crash
- Made Shift+Space also return you back to the editor

## v0.9
- After applying in multi-select, shape properties will be updated immediately
- Added shape multi-duplicate. This lets you duplicate a shape a specified
  number of times and the duplicates will be automatically multi-selected
- Added keyboard shortcuts: Save - Ctrl+S, Preview - Space, Play - Shift+Space
- Moving shapes to other platforms is now an option in multi-select
- Added ability to copy and paste shapes in multi-select

## v0.8
- Fixed bug in the shape generator that caused the editor to break

## v0.7
- Added shape colour option to multi-select
- Added rect height option to ellipse and sine wave generators
- Added parametric equation generator

## v0.6
- Improved description for the shape multi-selection panel
- Added a label for the preview speed slider
- Added a tip about arithmetic evaluation
- Added ability to delete selected shapes in multi-select

## v0.5
- Make polygon merger work with scaled polygons
- Fix bug where chat scrolls to the top when you enter the map editor
- Added multi-select for shapes

## v0.4
- Fix annoying bug where chat would scroll up when you click it

## v0.3
- Moved the chat box to a better place
- Fixed the bug where the chat box disappears if you get disconnected from
  the server while editing a map
- Added option for easing gradients

## v0.2
- Added automatic checking of updates (you'll still have to install them
  manually)
- Added generators for linear and radial gradients
- Fixed bug in checkboxes
- Added changelog.md

## v0.1
First release

Features:
- The chat is visible in the map editor
- Vertex editor
- (Buggy) Merge multiple polygons into one
- Easily generate ellipses, spirals and sine waves
- Move shapes to other platforms
- Ability to use your browser's colour picker for changing colours
- Evaluate arithmetic in number fields by pressing Shift+Enter
  (example: type `100*2+50` into X position field and press Shift+Enter)
- Change the speed of map testing in the editor
