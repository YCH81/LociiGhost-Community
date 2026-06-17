/** @type {import('tailwindcss').Config} */
export default {
    content: ['./src/**/*.{astro,html,js,jsx,ts,tsx,md,mdx,svelte,vue}'],
    theme: {
        extend: {
            colors: {
                // Sage palette matching the main project's docs/index.html
                // and the LociiGhost macOS app accent. Keep tokens stable
                // so the rest of the UI can `bg-sage` / `text-sage-dark`
                // without remembering hex codes.
                sage: {
                    DEFAULT: '#7fa389',
                    dark: '#5f7d68',
                    light: '#a8c2b1',
                },
                sand: '#fbf7ef',
                ink: '#2d3748',
                muted: '#6b7280',
                // Mushroom type colors — match Pikmin Bloom decoration
                // pikmin tints so flying users recognise them at a glance.
                mushroom: {
                    red: '#dc2626',
                    yellow: '#eab308',
                    blue: '#2563eb',
                    white: '#e5e7eb',
                    purple: '#9333ea',
                    gray: '#6b7280',
                    rock: '#78716c',
                    wing: '#ec4899',
                    rainbow: '#f59e0b',
                },
            },
            fontFamily: {
                sans: [
                    '-apple-system',
                    'BlinkMacSystemFont',
                    '"PingFang TC"',
                    '"Noto Sans TC"',
                    'sans-serif',
                ],
            },
        },
    },
    plugins: [],
};
