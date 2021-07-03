import browser from "webextension-polyfill";

const script = document.createElement("script");
script.src = browser.runtime.getURL("injector.js");
document.head.appendChild(script);
