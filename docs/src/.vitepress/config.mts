import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";
// import del from 'rollup-plugin-delete';

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  title: 'DimensionalData.jl',
  description: "Datasets with named dimensions",
  lastUpdated: true,
  cleanUrls: true,
  outDir: 'REPLACE_ME_DOCUMENTER_VITEPRESS', // This is required for MarkdownVitepress to work correctly...
  head: [['link', { rel: 'icon', href: '/DimensionalData.jl/dev/favicon.ico' }]],

  // vite: {
  //   build: {
  //     rollupOptions: {
  //       plugins: [
  //         del({ targets: ['dist/*', 'build/*'], verbose: true })
  //       ]
  //     },
  //   },
  // },

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
    logo: { src: 'https://private-user-images.githubusercontent.com/32276930/362385498-84c99edd-2971-483e-8d09-589a6e0c63ba.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjQ4NjUxNzEsIm5iZiI6MTcyNDg2NDg3MSwicGF0aCI6Ii8zMjI3NjkzMC8zNjIzODU0OTgtODRjOTllZGQtMjk3MS00ODNlLThkMDktNTg5YTZlMGM2M2JhLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDA4MjglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwODI4VDE3MDc1MVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTNhZDU5MDllMjA4Nzk2YWVlZTZiNGZlNzQ3MzYzMjA4MmY4NzQ2MzYxNmI2NzdmZWE0YzczZjY4ZjU4MDRmZjEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.jAOORcfEugQH01_KK_oOg4zVE74TBKr680oZ8Wvhhj4', width: 24, height: 24 },
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
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
          { text: 'Extending DimensionalData', link: '/extending_dd' },
        ],
      },
    ],

    sidebar: [
      {
        text: 'Getting Started', link: '/basics',
        items: [
          { text: 'Dimensions', link: '/dimensions' },
          { text: 'Selectors', link: '/selectors' },
          { text: 'DimArrays', link: '/dimarrays' },
          { text: 'DimStacks', link: '/stacks' },
          { text: 'GroupBy', link: '/groupby' },
          { text: 'Dimension-aware broadcast', link: '/broadcast_dims.md' },
          { text: 'Getting information', link: '/get_info' },
          { text: 'Object modification', link: '/object_modification' },
        ]},
        { text: 'Integrations', link: '/integrations',
          items: [
            { text: 'Plots and Makie', link: '/plots' },
            { text: 'Tables and DataFrames', link: '/tables' },
            { text: 'CUDA and GPUs', link: '/cuda' },
            { text: 'DiskArrays', link: '/diskarrays' },
            { text: 'Extending DimensionalData', link: '/extending_dd' },
          ],
        },
        { text: 'API Reference', link: '/api/reference',
          items: [
            { text: 'Dimensions Reference', link: '/api/dimensions' },
            { text: 'LookupArrays Reference', link: '/api/lookuparrays' },
          ],
        },
    ],
    editLink: {
      pattern: 'https://github.com/rafaqz/DimensionalData.jl/edit/master/docs/src/:path'
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/rafaqz/DimensionalData.jl' },
    ],
    footer: {
      message: 'Made with <a href="https://github.com/LuxDL/DocumenterVitepress.jl" target="_blank"><strong>DocumenterVitepress.jl</strong></a>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}. Released under the MIT License.`
    }
  }
})
