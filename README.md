# kklee

A [bonk.io](https://bonk.io) mod that extends the functionality of the map
editor.

[Discord server](https://discord.gg/kW389FqMz2)

[Guide](./guide.md)

## Installing as an extension

Download the latest kklee-(version)**_.zip_** file from
[Releases](https://github.com/kklkkj/kklee/releases).

<details>
<summary>In Firefox</summary>

**Note:** You will have to do this after every time you restart the browser.

1. Go to `about:debugging#/runtime/this-firefox`
2. Click `Load temporary addon` and open the zip file.

</details>

<details>
<summary>In Chrome (and other Chromium-based browsers, hopefully)</summary>

1. Go to `chrome://extensions/`
2. Enable `Developer mode` in the top-right corner of the page.
3. Drag and drop the zip file into the page.

</details>

## Installing as a userscript (for Tampermonkey, Violentmonkey, etc)

Userscripts require a userscript manager such as Violentmonkey or Tampermonkey,
and [Excigma's code injector userscript](https://greasyfork.org/en/scripts/433861-code-injector-bonk-io).

The userscript is available in [Releases](https://github.com/kklkkj/kklee/releases)
as kklee-(version)**_.user.js_**.

## "It doesn't work"

Did you:

- Disable any extensions that are incompatible with kklee, such as
  Bonk Leagues Client
- Refresh Bonk.io after installing
- Download the correct file from Releases?

It is also possible that a recent bonk.io update broke the extension and it
needs to be fixed.

---

## Building

<details>
<summary>Ignore this if you just want to install the extension</summary>

1. Install the following:
   - [Node.js](https://nodejs.org/) (v16.3.0)
   - [Nim](https://nim-lang.org/) (v1.6.0)
2. Run `npm ci` to install npm dependecies.
3. Run `nimble install -d` to install nimble dependencies.
4. Run `npm run build`.
5. Either:
   - Run `npm run test` to open a temporary browser session with the extension.
   - Run `npm run build-extension` to build the zip file and userscript.
     The file will be in the `build` directory.

</details>
