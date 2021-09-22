function injector(bonkCode) { 
  window.onbeforeunload = function () { return "Are you sure?"; };

  const kklee = {};
  window.kklee = kklee;

  let src = bonkCode;

  const mapObjectName =
    src.match(/rxid:[a-zA-Z0-9]{3}\[\d+\]/)[0].split(":")[1];
  // Escape regex special characters
  const monEsc = mapObjectName.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1");
  const varArrName = mapObjectName.split("[")[0];

  // When a new map object is created, also assign it to a global variable
  src = src.replace(
    new RegExp(`(${monEsc}=[^;]+;)`, "g"),
    `$1window.kklee.mapObject=${mapObjectName};\
if(window.kklee.afterNewMapObject)window.kklee.afterNewMapObject();`
  );

  const mapEncoderName =
    src.match(new RegExp(`${monEsc}=(.)\\[.{1,25}\\]\\(\\);`))[1];

  src = src.replace(
    new RegExp(`function ${mapEncoderName}\\(\\)\\{\\}`, "g"), 
    `function ${mapEncoderName}(){};\
window.kklee.mapEncoder=${mapEncoderName};`
  );

  /*
  This function contains some useful stuff
    function j0Z() {
        z5i[977] = -1; // selected body
        z5i[450] = -1; // selected spawn
        z5i[462] = -1; // selected capzone
        p4Z(); // update left box
        v4Z(); // update right box, takes parameter for selected fixture
        n4V.a1V();
        B4Z(true); // update rendering stuff. I'll use "true" as the parameter
        M4Z(); // spawns and physics shapes warnings
        y0Z(); // update undo and redo buttons
        I6s(); // update mode dropdown selection
    }
  */
  const theResetFunction = src.match(new RegExp("function ...\\(\\){.{0,40}\
(...\\[\\d+\\]=-1;){2}.{0,40}(...\\(true\\);).{0,40}(...\\(\\);){2}[^}]+\\}"
  ))[0];

  const resetFunctionNames = 
    theResetFunction
      // Function body excluding last semicolon
      .match(/(?<=\{).+(?=;\})/)[0]
      .split(";")
      // Exclude the weird obfuscation function
      .filter(s => !s.match(/.+(\.).+\(\)/))
    ;
  const updateFunctionNames =
    resetFunctionNames
      .slice(3)
      .map(s => s.split("(")[0])
    ;
  const currentlySelectedNames =
    resetFunctionNames
      .slice(0, 3)
      .map(s => s.split("=")[0])
    ;
  if(resetFunctionNames.length !== 9)
    throw "resetFunctionNames length is not 9";

  let ufInj = "";

  const apiUpdateFunctionNames = 
    ["LeftBox", "RightBoxBody", "Renderer","Warnings", 
      "UndoButtons","ModeDropdown"];
  for(const i in updateFunctionNames) {
    const on = updateFunctionNames[i], nn = apiUpdateFunctionNames[i];

    ufInj += `let ${on}OLD=${on};${on}=function(){${on}OLD(...arguments);\
if(window.kklee.afterUpdate${nn})window.kklee.afterUpdate${nn}(...arguments);};\
window.kklee.update${nn}=${on};`;

  }

  const apiCurrentlySelectedNames =
    ["Body", "Spawn", "CapZone"];
  for(const i in currentlySelectedNames) {
    const on = currentlySelectedNames[i], nn = apiCurrentlySelectedNames[i];

    ufInj += `window.kklee.getCurrent${nn}=function(){return ${on};};\
window.kklee.setCurrent${nn}=function(v){return ${on}=v;};`;
  }

  src = src.replace(
    theResetFunction, 
    `${theResetFunction};{${ufInj}};`
  );

  // Only part of the function body
  const saveHistoryFunction =
    src.match(
      new RegExp(
        `function ...\\(\\)\\{.{1,170}${varArrName}\\[\\d{1,3}\\]--;\\}\
${varArrName}\\[\\d{1,3}\\].{1,40}\\]\\(JSON\\[.{1,40}\\]\\(${monEsc}\\)`
      ))[0];
  const saveHistoryFunctionName =
    saveHistoryFunction.match(/(?<=function )...(?=\(\))/)[0];
  const newSaveHistoryFunction = saveHistoryFunction.replace(
    new RegExp("(function ...\\(\\)\\{)"),
    "$1window.kklee.afterSaveHistory();"
  );
  src = src.replace(
    saveHistoryFunction,
    `;window.kklee.setMapObject=\
function(m){${mapObjectName}=m;window.kklee.mapObject=m;};\
window.kklee.saveToUndoHistoryOLD=${saveHistoryFunctionName};\
${newSaveHistoryFunction}`
  );

  const dbOpenRequest = window.indexedDB.open("kkleeStorage_347859220", 1);
  let db;
  kklee.backups = [];

  dbOpenRequest.onsuccess = () => {
    db = dbOpenRequest.result;
    db.transaction("backups");
    const transaction = db.transaction("backups");
    const getRequest = transaction.objectStore("backups").get(1);
    getRequest.onsuccess = () => {
      kklee.backups = getRequest.result;
    };
    getRequest.onerror = event => {
      console.error(event);
      alert("kklee: unable to get backups from database");
    };
  };
  function saveBackups() {
    if(!db) return;
    const transaction = db.transaction("backups", "readwrite");
    transaction.objectStore("backups").put(kklee.backups, 1);
    db.onerror = console.error;
  }
  dbOpenRequest.onerror = event => {
    console.error(event);
    alert("kklee: unable to open IndexedDB");
  };
  dbOpenRequest.onupgradeneeded = event => {
    const db = event.target.result;
    const b = db.createObjectStore("backups");
    b.put(JSON.parse(localStorage.kkleeMapBackups || "[]"), 1);
    delete localStorage.kkleeMapBackups;
  };

  kklee.getBackupLabel =
    b => `${b.mapLabel} - ${new Date(b.timestamp).toLocaleString()}`;
  kklee.loadBackup = b => 
    kklee.setMapObject(kklee.mapEncoder.decodeFromDatabase(b.mapData));

  function newBackupSessionId() {
    kklee.backupSessionId =
      Date.now().toString(36) + Math.random().toString(36);
  }
  function backUpMap() {
    const mapLabel = `${kklee.mapObject.m.n} by ${kklee.mapObject.m.a}`;
    const mapData = kklee.mapEncoder.encodeToDatabase(kklee.mapObject);
    const lastBackup = kklee.backups[kklee.backups.length-1];

    if (lastBackup && lastBackup.sessionId == kklee.backupSessionId &&
        lastBackup.mapLabel == mapLabel) {
      lastBackup.mapData = mapData;
      lastBackup.timestamp = Date.now();
    } else {
      kklee.backups.push({
        sessionId: kklee.backupSessionId, mapLabel: mapLabel, 
        timestamp: Date.now(), mapData: mapData
      });
    }

    let i = kklee.backups.length - 1;
    let size = 0;
    while (i >= 0) {
      size += kklee.backups[i].mapData.length;
      if (size > 1e6)
        break;
      else
        i--;
    }

    kklee.backups = kklee.backups.slice(i + 1);
    saveBackups();
  }
  newBackupSessionId();
  // ID will be different every time a new room is made
  document.getElementById("mainmenuelements")
    .addEventListener("mousemove", () => newBackupSessionId());

  window.kklee.afterSaveHistory = () => {
    backUpMap();
  };

  // Replace Float64Array instances with normal arrays
  window.kklee.saveToUndoHistory = () => {
    function fix(obj) {
      for (const k of Object.keys(obj)) {
        if (obj[k] instanceof Float64Array)
          obj[k] = [...obj[k]];
        else if (obj[k] instanceof Object)
          fix(obj[k]);
      }
    }
    fix(kklee.mapObject);
    window.kklee.saveToUndoHistoryOLD();
  };

  /*
    Prevent removal of event listener for activating chat with enter key when
    lobby is hidden
  */
  src = src.replace(
    new RegExp("(?<=this\\[.{10,20}\\]=function\\(\\)\\{.{20,40}\
this\\[.{10,20}\\]=false;.{0,11})\\$\\(document\\)\\[.{10,20}\\]\\(.{10,20},\
.{3,4}\\);"),
    ""
  );

  /*
  Colour picker
    this["showColorPicker"] = function(H0R, k0R, C0R, u0R) {
        var Z8D = [arguments];
        Z8D[6] = E8TT;
        j8D[8]["style"]["backgroundColor"] = j7S[29]["numToHex"](Z8D[0][0]);
        Z8D[2] = K8u(Z8D[0][0]);
        j8D[41] = Z8D[2]["hue"];
        j8D[26] = Z8D[2]["brightness"];
        j8D[38] = Z8D[2]["saturation"];
        j8D[88] = Z8D[0][2];
        j8D[22] = Z8D[0][3];
        j8D[32] = Z8D[0][0];
        M8u(false);
        e8u(Z8D[0][1]);
        j8D[1]["style"]["display"] = "block";
    }
  */
  src = src.replace(new RegExp(
    "((?<=this\\[.{10,25}\\]=function\\(.{3,4},.{3,4}\
,.{3,4},.{3,4}\\)\\{).{50,250}(.{3,4}\\[.{0,25}\\]=.{3,4}\\[.{0,30}\\];){3}\
.{0,75}.{3,4}\\(false\\).{0,75};\\};(?=.{0,200000}return \\{hue))","g"
  ), 
  `${""}window.kklee.showColourPickerArguments=[...arguments];\
document.getElementById("kkleeColourInput").value="#"+arguments[0]\
.toString(16).padStart(6,"0");$1;\
let Kscpa=this["showColorPicker"];window.kklee.setColourPickerColour=\
function(c){Kscpa(c,...window.kklee.showColourPickerArguments.slice(1));};`
  );
  // Map editor test TimeMS
  window.kklee.editorPreviewTimeMs = 30;
  src = src.replace(
    new RegExp("(?<=(?<!Infinity.{0,300});.{3,4}\\[.{1,20}\\]\\=)30\
(?=;.{0,30}while.{10,150}Date.{0,5000})","g"),
    "window.kklee.editorPreviewTimeMs"
  );

  const mgfs = parent.document.getElementById("maingameframe").style;
  const bcs = document.getElementById("bonkiocontainer").style;
  const me = document.getElementById("mapeditor").style;
  const xpb = document.getElementById("xpbarcontainer").style;
  document.getElementById("prettymenu").style.boxShadow = "none";

  let fullPage = false;
  let a = () => {
    mgfs.position = "fixed";
    mgfs.zIndex = "10000";
    mgfs.marginTop = "";
    const s = Math.min(innerWidth/730,innerHeight/500);
    bcs.width = `${s * 730}px`;
    bcs.height = `${s * 500}px`;
    bcs.border = "none";
    xpb.visibility = "hidden";
    me.maxWidth = `${s * 730 * 0.9}px`;
    me.maxHeight = `${s * 500 * 0.9}px`;
    parent.document.body.style.overflowY = "hidden";
  };
  kklee.toggleFullPage = () => {
    fullPage = !fullPage;
    if (fullPage) a();
    else {
      mgfs.position = "";
      mgfs.zIndex = "";
      bcs.border = "";
      xpb.visibility = "inherit";
      parent.document.body.style.overflowY = "";
    }
  };
  window.addEventListener("resize", function(){if(fullPage) setTimeout(a,50);});

  kklee.dataLimitInfo = () => {
    try {
      const d = atob(window.LZString.decompressFromEncodedURIComponent(
        kklee.mapEncoder.encodeToDatabase(kklee.mapObject))).length;
      return `${d}/102400 bytes`;
    } catch {
      return "Over data limit";
    }
  };

  require("./nimBuild.js");
  console.log("kklee injector run");
  return src;
}

if(!window.bonkCodeInjectors)
  window.bonkCodeInjectors = [];
window.bonkCodeInjectors.push(bonkCode => {
  try {
    return injector(bonkCode);
  } catch (error) {
    alert(
      `Whoops! kklee was unable to load.


This may be due to an update to Bonk.io. If so, please report this error!


This could also be because you have an extension that is incompatible with \
kklee, such as the Bonk Leagues Client. You would have to disable it to use \
kklee.
    `);
    throw error;
  }
});
console.log("kklee injector loaded");

const currentVersion = require("../dist/manifest.json").version
  .split(".").map(Number); // "0.10" --> [0,10]

(async () => {
  const req = await fetch("https://api.github.com/repos/kklkkj/kklee/releases");
  const releases = await req.json();
  let outdated = false;
  for (const r of releases) {
    // "v0.10" --> [0,10]
    const version = r.tag_name.substr(1).split(".").map(Number); 
    if (version.length != 2 || isNaN(version[0]) || isNaN(version[1]))
      continue;
    if (version[0] > currentVersion[0] ||
        version[0] == currentVersion[0] && version[1] > currentVersion[1]) {
      outdated = true;
      break;
    }
  }
  if (!outdated)
    return;

  try {
    const el = document.createElement("span");
    el.textContent = "A new version of kklee is available! Click this";
    el.style = "position: absolute; background: linear-gradient(#33a, #d53);\
line-height: normal;";
    el.onclick = () => window.open("https://github.com/kklkkj/kklee");
    parent.document.getElementById("bonkioheader").appendChild(el);
  } catch(error) {
    console.error(error);
    alert("A new version of kklee is available!");
  }

})().catch(err => {
  console.error(err);
  alert("Something went wrong with checking if the current version of kklee is \
outdated");
});
