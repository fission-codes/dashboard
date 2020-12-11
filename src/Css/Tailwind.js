import * as kit from "fission-kit"
import defaultTheme from "tailwindcss/defaultTheme.js"


export default {

  darkMode: "media",


  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////
  theme: {

    // Colors
    // ======

    colors: {
      ...kit.dasherizeObjectKeys(kit.colors),

      "inherit": "inherit",
      "transparent": "transparent"
    },


    // Fonts
    // =====

    fontFamily: {
      ...defaultTheme.fontFamily,

      body: [ kit.fonts.body, ...defaultTheme.fontFamily.sans ],
      display: [ kit.fonts.display, ...defaultTheme.fontFamily.serif ],
      mono: [ kit.fonts.mono, ...defaultTheme.fontFamily.mono ],
    }

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: { extend: {}}
}
