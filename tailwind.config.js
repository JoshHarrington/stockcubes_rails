const { colors } = require('tailwindcss/defaultTheme')

module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          '900': 'hsl(177, 40%, 30%)',
          '800': 'hsl(177, 40%, 36%)',
          '700': 'hsl(177, 40%, 42%)',
          '600': 'hsl(177, 40%, 48%)',
          '500': 'hsl(177, 40%, 54%)',
          '400': 'hsl(176, 49%, 60%)',
          '300': 'hsl(177, 50%, 65%)',
          '200': 'hsl(177, 50%, 70%)',
          '150': 'hsl(177, 50%, 76%)',
          '100': 'hsl(177, 50%, 82%)',
          '50': 'hsl(177, 50%, 88%)'
        },
        "black-a": {
          '500': 'rgba(0, 0, 0, .5)',
          '600': 'rgba(0, 0, 0, .6)',
          '700': 'rgba(0, 0, 0, .7)',
          '800': 'rgba(0, 0, 0, .8)'
        }
      },
      fontFamily: {
        'sans': ['Lato', 'system-ui', '-apple-system', 'BlinkMacSystemFont', "Segoe UI", 'Roboto', "Helvetica Neue", 'Arial', "Noto Sans", 'sans-serif', "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"]
      }
    },
    fontSize: {
      'xs': '1.05rem',
      'sm': '1.225rem',
      'base': '1.4rem',
      'lg': '1.575rem',
      'xl': '1.75rem',
      '2xl': '2.1rem',
      '3xl': '2.625rem',
      '4xl': '3.15rem',
      '5xl': '4.2rem',
      '6xl': '5.6rem',
    }
  },
  variants: {
    padding: ['responsive', 'hover', 'focus'],
    borderStyle: ['responsive', 'hover', 'focus'],
    borderWidth: ['responsive', 'hover', 'focus'],
  },
  plugins: [],
}
