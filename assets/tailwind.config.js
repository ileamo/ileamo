const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    container: {},
    extend: {
      colors: {
        cyan: colors.cyan,
      }
    }
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
