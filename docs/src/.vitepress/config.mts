import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";
import path from 'path'
// import del from 'rollup-plugin-delete';
function getBaseRepository(base: string): string {
  if (!base) return '/';
  // I guess if deploy_url is available. From where do I check this ?
  const parts = base.split('/').filter(Boolean);
  return parts.length > 0 ? `/${parts[0]}/` : '/';
}

const baseTemp = {
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',// TODO: replace this in makedocs!
}

const navTemp = {
  nav: [
    { text: 'Home', link: '/' },
    { text: 'Getting Started', link: '/basics' },
    { text: 'Dimensions', link: '/dimensions' },
    { text: 'DimArrays', link: '/dimarrays' },
    { text: 'Selectors', link: '/selectors' },
    { text: 'Integrations',
      items: [
        { text: 'Integrations', link: '/integrations'},
        { text: 'Plots and Makie', link: '/plots' },
        { text: 'Tables and DataFrames', link: '/tables' },
        { text: 'CUDA and GPUs', link: '/cuda' },
        { text: 'DiskArrays', link: '/diskarrays' },
        { text: 'Xarray', link: '/xarray' },
        { text: 'Extending DimensionalData', link: '/extending_dd' },
        { text: 'FFT', link: '/fft' },
      ],
    },
  ],
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker'
  }
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  title: 'DimensionalData.jl',
  description: "Datasets with named dimensions",
  lastUpdated: true,
  cleanUrls: true,
  outDir: 'REPLACE_ME_DOCUMENTER_VITEPRESS', // This is required for MarkdownVitepress to work correctly...
  head: [
    ['link', { rel: 'icon', href: '/DimensionalData.jl/dev/favicon.ico' }],
    ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
    ['script', {src: `${baseTemp.base}siteinfo.js`}]
  ],
  vite: {
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('REPLACE_ME_DOCUMENTER_VITEPRESS_DEPLOY_ABSPATH'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    build: {
      assetsInlineLimit: 0, // so we can tell whether we have created inlined images or not, we don't let vite inline them
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        // If there are other packages that need to be processed by Vite, you can add them here.
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },

  markdown: {
    math: true,
    config(md) {
      md.use(tabsMarkdownPlugin),
      md.use(mathjax3),
      md.use(footnote)
    },
    // https://shiki.style/themes
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: { src: 'https://private-user-images.githubusercontent.com/32276930/361481134-781ae61d-3316-4c69-a128-6626ea8a3a37.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjQ2ODUxMTYsIm5iZiI6MTcyNDY4NDgxNiwicGF0aCI6Ii8zMjI3NjkzMC8zNjE0ODExMzQtNzgxYWU2MWQtMzMxNi00YzY5LWExMjgtNjYyNmVhOGEzYTM3LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDA4MjYlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwODI2VDE1MDY1NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWExMWMzZmI5YThmZTEwNzNiZGEyZGRiOTNlOTRhOTI0MTc5NTA5ZDlmNmJmODhiMzYzMDg3OTBhYmZmYzVhN2YmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.X49onLbQxzykz_p8wliGdF063XqX4tzAsBtaxaXagts', width: 24, height: 24 },
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav,
    sidebar: [
      {
        text: 'Getting Started', link: '/basics',
        items: [
          { text: 'Dimensions', link: '/dimensions' },
          { text: 'Selectors', link: '/selectors' },
          { text: 'DimArrays', link: '/dimarrays' },
          { text: 'DimStacks', link: '/stacks' },
          { text: 'GroupBy', link: '/groupby' },
          { text: 'Dimension-aware broadcast', link: '/broadcasts.md' },
          { text: 'Getting information', link: '/get_info' },
          { text: 'Object modification', link: '/object_modification' },
        ]},
        { text: 'Integrations', link: '/integrations',
          items: [
            { text: 'Plots and Makie', link: '/plots' },
            { text: 'Tables and DataFrames', link: '/tables' },
            { text: 'CUDA and GPUs', link: '/cuda' },
            { text: 'DiskArrays', link: '/diskarrays' },
            { text: 'Xarray', link: '/xarray' },
            { text: 'Extending DimensionalData', link: '/extending_dd' },
          ],
        },
        { text: 'API Reference', link: '/api/reference',
          items: [
            { text: 'Dimensions Reference', link: '/api/dimensions' },
            { text: 'Lookups Reference', link: '/api/lookups' },
          ],
        },
    ],
    editLink: {
      pattern: 'https://github.com/rafaqz/DimensionalData.jl/edit/main/docs/src/:path'
    },

    socialLinks: [
      // { icon: 'github', link: 'https://github.com/rafaqz/DimensionalData.jl' },
    ],
    footer: {
      message: 'Made with <a href="https://github.com/LuxDL/DocumenterVitepress.jl" target="_blank"><strong>DocumenterVitepress.jl</strong></a>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}. Released under the MIT License.`
    }
  }
})
