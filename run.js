const path = require("path");
const spawn = require("cross-spawn");


(async () => {
    let script = process.argv.slice(2)[0] || "setup.sh";
    const cmd = spawn("sh", [script], {
        stdio: "inherit",
        env: Object.assign({}, process.env, {
            FORCE_COLOR: true
        })
    });

    cmd.on("close", code => {
        if (code === 0) {
            resolve();
        } else {
            console.error(code);
        }
    });
})();
