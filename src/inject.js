const kklee = {};
window.kklee = kklee;

(async ()=>{
  window.onbeforeunload = function () { return "Are you sure?"; };

  const bonkScriptResponse = await fetch("https://bonk.io/js/alpha2s.js?real");
  let src = await bonkScriptResponse.text();

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

  // This function contains some useful stuff
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
        `function ...\\(\\)\\{.{1,150}${varArrName}\\[\\d{1,3}\\]--;\\}\
${varArrName}\\[\\d{1,3}\\].{1,40}\\]\\(JSON\\[.{1,40}\\]\\(${monEsc}\\)`
      ))[0];
  const saveHistoryFunctionName =
    saveHistoryFunction.match(/(?<=function )...(?=\(\))/)[0];

  src = src.replace(
    saveHistoryFunction,
    `window.kklee.saveToUndoHistory=${saveHistoryFunctionName};\
${saveHistoryFunction}`
  );

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

  const script = document.createElement("script");
  script.text = src;
  document.head.appendChild(script);
  require("./nimBuild.js");

})().catch(err => {
  console.error("kklee error: ", err);
  alert(
    "Whoops! KKLEE was unable to load. This may be due to an update to Bonk.io.\
\n\nPlease report this error!"
  );
});
