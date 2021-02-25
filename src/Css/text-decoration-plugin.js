import plugin from "tailwindcss/plugin.js"

export default plugin(
    /**
     * Adds e.g. this:
     *  
     * .decoration-color-purple {
     *    text-decoration-color: <purple>;
     * }
     * 
     * And this:
     * 
     * .decoration-thickness-1\.5 {
     *    text-decoration-thickness: 1.5px;
     * }
     * 
     * Variants can be configured via the `textDecoration` key.
     */
    function ({ addUtilities, e, theme, variants }) {
        const colors = theme("colors", {})
        const thicknesses = theme("textDecorationThickness", {})
        const decorationVariants = variants("textDecoration", [])

        const textDecorationColorUtility = Object.entries(colors).map(([name, color]) => ({
            [`.decoration-color-${e(name)}`]: {
                textDecorationColor: `${color}`
            }
        }))

        const textDecorationThicknessUtility = Object.entries(thicknesses).map(([name, thickness]) => ({
            [`.decoration-thickness-${e(name)}`]: {
                textDecorationThickness: `${thickness}`
            }
        }))

        addUtilities(textDecorationColorUtility, decorationVariants)
        addUtilities(textDecorationThicknessUtility, decorationVariants)
    },
    {
        theme: {
            textDecorationThickness: {
                "1": "1px",
                "1.5": "1.5px",
                "2": "2px",
            },
        },
        variants: {
            textDecorationThickness: ["responsive"],
        },
    }
)
