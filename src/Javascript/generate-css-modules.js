import * as elmTailwindModules from "elm-tailwind-modules"
import tailwindConfig from "../Css/Tailwind.js"
import autoprefixer from "autoprefixer"
import postcssImport from "postcss-import"
import * as postcss from "postcss"
import tailwindcss from "tailwindcss"
import { promises as fs } from "fs"

const etmConfig = {
    directory: "src/Generated",
    moduleName: "Tailwind",
    generateDocumentation: true,
    // custom stuff
    inputCssFile: "src/Css/Application.css",
    outputCssFile: "build/application.css",
}

const addLogPrefix = line => `[elm-tailwind-modules] ${line}`
const logFunction = message => console.log(message.split("\n").map(addLogPrefix).join("\n"))

const elmTailwindModulesPlugin = elmTailwindModules.asPostcssPlugin({
    moduleName: etmConfig.moduleName,
    tailwindConfig: tailwindConfig,
    generateDocumentation: etmConfig.generateDocumentation,
    logFunction,
    modulesGeneratedHook: async generated => elmTailwindModules.writeGeneratedFiles({
        directory: etmConfig.directory,
        moduleName: etmConfig.moduleName,
        logFunction,
        generated
    })
});

(async () => {
    const inputCss = await fs.readFile(etmConfig.inputCssFile, { encoding: "utf8" })

    const result = await postcss.default([
        postcssImport,
        tailwindcss(tailwindConfig),
        autoprefixer,
        elmTailwindModulesPlugin
    ]).process(inputCss, {
        from: etmConfig.inputCssFile,
        to: etmConfig.outputCssFile,
    })

    logFunction(`Saving remaining global css to ${etmConfig.outputCssFile}`)
    await fs.writeFile(etmConfig.outputCssFile, result.content)
})()
