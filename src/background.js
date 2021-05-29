import browser from "webextension-polyfill";

browser.webRequest.onBeforeRequest.addListener(
  (req) => {
    if (req.url.includes("/js/alpha") && !req.url.includes("?"))
      return {
        redirectUrl: browser.runtime.getURL("inject.js")
      };
  },
  { urls: ["*://bonk.io/*"] },
  ["blocking"]
);
