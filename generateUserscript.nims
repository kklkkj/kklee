import json, strformat

let
  manifest = parseJson(readFile("./dist/manifest.json"))
  userScriptSrc = &"""
// ==UserScript==
// @name         kklee
// @version      {manifest["version"].getStr()}
// @author       kklkkj
// @namespace    https://github.com/kklkkj/
// @description  {manifest["description"].getStr()}
// @homepage     {manifest["homepage_url"].getStr()}
// @match        https://bonk.io/gameframe-release.html
// @run-at       document-start
// @grant        none
// ==/UserScript==

{readFile("./dist/injector.js")}
"""

writeFile("./web-ext-artifacts/kklee.user.js", userScriptSrc)
