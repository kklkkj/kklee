# kklee
A browser extension that extends the functionality of the map editor in
[Bonk.io](https://bonk.io).

## Features
- The chat is visible in the map editor
- Vertex editor
- (Buggy) Merge multiple polygons into one
- Easily generate ellipses, spirals, sine waves and gradients
- Move shapes to other platforms
- Ability to use your browser's colour picker for changing colours
- Evaluate arithmetic in number fields by pressing Shift+Enter
  (example: type `100*2+50` into X position field and press Shift+Enter)
- Change the speed of map testing in the editor

---

## Installing
This extension isn't hosted on the any extension stores, so you will have to
install it manually from a local file. This also means that you will have to
update the extension manually when new versions are released.

***Warning:*** Before installing any extension this way, you should check the
`permissions` in `manifest.json` for anything suspicious, as the browser won't immediately warn you
about them.

***
First, download the latest `kklee-[version].zip` file from
[Releases](https://github.com/kklkkj/kklee/releases).
Then, you will have to add the extension to your browser.

### In Firefox
**Note:** You will have to do this after every time you restart the browser.
1. Go to `about:debugging#/runtime/this-firefox`
2. Click `Load temporary addon` and open the zip file.
### In Chrome (and other Chromium-based browsers, hopefully)
1. Go to `chrome://extensions/`
2. Enable `Developer mode` in the top-right corner of the page.
3. Drag and drop the zip file into the page.
4. Open the `details` of the extension and disable `Allow access to file URLs`.

---

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
