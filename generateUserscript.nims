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

/*
  Usable with:
  https://greasyfork.org/en/scripts/433861-code-injector-bonk-io
*/
{readFile("./dist/injector.js")}
"""

let version = manifest["version"].getStr()
writeFile(&"./web-ext-artifacts/kklee-{version}.user.js",
  userScriptSrc)
