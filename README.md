# kklee
A browser extension that extends the functionality of the map editor in
[Bonk.io](https://bonk.io).

[Discord server](https://discord.gg/kW389FqMz2)

### Features
- Multi-select for platforms and shapes
- Vertex editor with ability to round corners and (buggy) ability to merge
  multiple polygons into one
- Easily generate ellipses, spirals, sine waves, gradients and custom equations
- Ability to use your browser's colour picker for changing colours
- Evaluate arithmetic in number fields by pressing Shift+Enter
  (example: type `100*2+50` into X position field and press Shift+Enter)
- Change the speed of map testing in the editor
- The chat is visible in the map editor
- Ability to transfer map ownership
- Keyboard shortcuts: Save - Ctrl+S, Preview - Space, Play - Shift+Space,
  Return to editor after pressing play - Shift+Esc

## Installing

**Warning:** Before installing any extension this way, you should check the
`permissions` in `manifest.json` for anything suspicious, as the browser won't
immediately warn you about them.

[Download the latest `kklee-[version].zip` file from Releases.](
  https://github.com/kklkkj/kklee/releases)

### In Firefox
**Note:** You will have to do this after every time you restart the browser.
1. Go to `about:debugging#/runtime/this-firefox`
2. Click `Load temporary addon` and open the zip file.
### In Chrome (and other Chromium-based browsers, hopefully)
1. Go to `chrome://extensions/`
2. Enable `Developer mode` in the top-right corner of the page.
3. Drag and drop the zip file into the page.

Newer versions will have to be installed manually like this too.

## It doesn't work
Did you:
- Disable any extensions that are incompatible with kklee, such as
  Bonk Leagues Client
- Refresh Bonk.io after installing

It is also possible that a recent Bonk.io update broke the extension and it
needs to be fixed.

---
---
##### Ignore this if you just want to install the extension.
## Building

1. Install the following:
    * [Node.js](https://nodejs.org/) (v16.3.0)
    * [Nim](https://nim-lang.org/) (v1.4.8)
2. Run `npm ci` to install npm dependecies.
3. Run `nimble install -d` to install nimble dependencies.
4. Run `npm run build`.
5. Either:
    - Run `npm run test` to open a temporary browser session with the extension.
    - Run `npm run build-extension` to build the zip file.
      The file will be in `web-ext-artifacts`.
