const path = require("path");
const child_process = require("child_process");

console.log(child_process.execSync(
  "nim js -d:release -o:./src/nimBuild.js ./src/main.nim", 
));

module.exports = {
  mode: "production",
  entry: {
    background: "./src/background.js",
    injector: "./src/injector.js",
    loadInjector: "./src/loadInjector.js",
    runInjectors: "./src/runInjectors.js"
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "dist")
  }
};
