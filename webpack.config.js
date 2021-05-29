const path = require("path");
const child_process = require("child_process");

console.log(child_process.execSync(
  "nim js -d:release -o:./src/nimBuild.js ./src/main.nim", 
));

module.exports = {
  mode: "production",
  entry: {
    background: "./src/background.js",
    inject: "./src/inject.js"
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "dist")
  }
};
