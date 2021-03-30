import * as kit from "fission-kit"
import defaultTheme from "tailwindcss/defaultTheme.js"
import textDecorationPlugin from "./text-decoration-plugin.js"
import aspectRatioPlugin from "@tailwindcss/aspect-ratio"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////
  theme: {

    // Colors
    // ======

    colors: {
      ...kit.dasherizeObjectKeys(kit.colors),

      // Darkmode colors that are less saturated for less eye strain on dark backgrounds
      // They fit in better, too 
      "darkmode-red": "#A73D54",
      "darkmode-purple": "#7760E5",

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
    },


    // Extensions
    // ==========

    extend: {
 
      maxWidth: {
        "xxs": "16rem",
      },

      minHeight: {
        "120px": "7.5rem",
      },
      
      boxShadow: {
        "inner-outline": "inset 0 0 0 2px rgba(100, 70, 250, .2)", // purple 20%
        "outline": "0 0 0 2px rgba(100, 70, 250, 0.4)", // purple 40%
        "outline-light": "0 0 0 2px rgba(255, 255, 255, 0.8)",
      },

      scale: {
        "25": ".25",
      },
      
    },

  },

  variants: [], // We use variants like focus, hover, breakpoints etc. via elm-css

  plugins: [
    textDecorationPlugin,
    aspectRatioPlugin,
  ],
}
