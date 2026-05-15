/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    './index.html',
    './src/**/*.{vue,js,ts}'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          bg:        { DEFAULT: '#FFFFFF',  dark: '#0A0A0A'  },
          surface:   { DEFAULT: '#EFEFED',  dark: '#222220'  },
          text:      { DEFAULT: '#1C1C1A',  dark: '#F5F4F0'  },
          muted:     { DEFAULT: '#5F5E5A',  dark: '#B4B2A9'  },
          secondary: { DEFAULT: '#444441',  dark: '#888780'  },
          accent:    { DEFAULT: '#C41E1E'                    },
          border:    { DEFAULT: '#C8C6BF',  dark: '#383836'  },
          strong:    { DEFAULT: '#1C1C1A',  dark: '#F5F4F0'  },
        },
      },
      fontFamily: {
        display: ['"Helvetica Neue"', 'Arial', 'sans-serif'],
        body:    ['system-ui', '-apple-system', 'sans-serif'],
      },
      fontSize: {
        'display-sm': ['clamp(32px, 5vw, 48px)', { lineHeight: '0.88', letterSpacing: '-0.03em' }],
        'display-lg': ['clamp(40px, 7vw, 64px)', { lineHeight: '0.88', letterSpacing: '-0.03em' }],
      },
    }
  },
  plugins: [require('@tailwindcss/typography')]
}
