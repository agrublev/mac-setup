const inquirer = require("inquirer");
const chalk = require("chalk");
const choices = [
    // {name: `${chalk.bold.green("test")}`, value: "organized/0test.sh"},
    {name: `${chalk.bold.green("xcode")}`, value: "organized/1xcode.sh"},
    {name: `${chalk.bold.green("zsh")}`, value: "organized/2zsh.sh"},
    {name: `${chalk.bold.green("brew")}`, value: "organized/3brew.sh"},
    {name: `${chalk.bold.green("apps")}`, value: "organized/4apps.sh"},
    {name: `${chalk.bold.green("macprefs")}`, value: "organized/5macprefs.sh"}];

const path = require("path");
const spawn = require("cross-spawn");


const runScript = async (script) => {
    // let script = process.argv.slice(2)[0] || "setup.sh";
    const cmd = spawn("sh", [script], {
        stdio: "inherit",
        env: Object.assign({}, process.env, {
            FORCE_COLOR: true
        })
    });
    return new Promise(resolve => {
        cmd.on("close", code => {
            if (code === 0) {
                resolve();
            } else {
                console.error(code);
                resolve()
            }
        });
    })
};


const choose = async () => {
    return inquirer.prompt([
        {
            type: "checkbox",
            name: "scripts",
            choices,
            message: `${chalk.bold.underline("Script to run:")}`,
            suggestOnly: false
        }
    ]).then(async ({scripts}) => {
        for (let script in scripts) {
            console.warn("-- Console sc", scripts[script]);
            await runScript(scripts[script])
        }
    });
};

(async () => {
    await choose()
})();
