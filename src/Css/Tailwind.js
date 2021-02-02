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
      
      boxShadow: {
        "inner-outline": "inset 0 0 0 2px rgba(100, 70, 250, .2)", // purple 20%
        "outline": "0 0 0 2px rgba(100, 70, 250, 0.4)", // purple 40%
        "outline-light": "0 0 0 2px rgba(255, 255, 255, 0.8)",
      },
      
    },

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: {
    extend: {
      backgroundColor: [ 'active', 'disabled' ],
      backgroundOpacity: [ 'active', 'disabled' ],
      boxShadow: [ 'dark' ],
      display: [ 'dark' ],
      maxWidth: [ 'responsive' ],
      textDecoration: [ 'dark' ],
      textColor: [ 'disabled' ],
    }
  },

  plugins: [
    function({ addUtilities, e, theme, variants }) {
      const colors = theme('colors', {})
      const decorationVariants = variants('textDecoration', [])

      const textDecorationColorUtility = Object.entries(colors).map(([name, color]) => ({
        [`.decoration-color-${e(name)}`]: {
          textDecorationColor: `${color}`
        }
      }))

      addUtilities(textDecorationColorUtility, decorationVariants)
    },
  ],
}
