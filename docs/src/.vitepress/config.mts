import type { DefaultTheme } from 'vitepress'
import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
const version= '0.25.8'

const VERSIONS: DefaultTheme.NavItemWithLink[] = [
  { text: `v${version} (current)`, link: '/' },
  { text: `Release Notes`, link: 'https://github.com/rafaqz/DimensionalData.jl/releases/' },
  // { text: `Contributing`, link: 'https://github.com/twoslashes/twoslash/blob/main/CONTRIBUTING.md' },
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: 'REPLACE_ME_WITH_DOCUMENTER_VITEPRESS_BASE_URL_WITH_TRAILING_SLASH',
  title: "DimensionalData",
  description: "Datasets with named dimensions",
  lastUpdated: true,
  cleanUrls: true,
  ignoreDeadLinks: true,
  
  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin)
    },
    // https://shiki.style/themes
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: { src: '/logoDD.png', width: 24, height: 24 },
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
      { text: 'Selectors', link: '/selectors' },
      { text: 'Integrations',
        items: [
          { text: 'Integrations', link: '/integrations' },
          { text: 'Tables and DataFrames', link: '/tables' },
          { text: 'Plots and Makie', link: '/plots' },
          { text: 'CUDA and GPUs', link: '/cuda' },
          { text: 'DiskArrays', link: '/diskarrays' },
          { text: 'Extending DimensionalData', link: '/ext_dd' },
        ],
      },
      {
        text: `v${version}`,
        items: VERSIONS,
      },
    ],

    sidebar: [
      {
        text: '',
        items: [
          { text: 'Getting Started', link: '/basics' },
          { text: 'Dimensions', link: '/dimensions' },
          { text: 'Selectors', link: '/selectors' },
          { text: 'GroupBy', link: '/groupby' },
          { text: 'Stacks', link: '/stacks' },
          { text: 'Lookup customazation', link: '/lookup_customization' },
          { text: 'Tables and DataFrames', link: '/tables' },
          { text: 'Plots and Makie', link: '/plots' },
          { text: 'CUDA and GPUs', link: '/cuda' },
          { text: 'DiskArrays', link: '/diskarrays' },
          { text: 'Extending DimensionalData', link: '/ext_dd' },
          { text: 'API Reference',
            items: [
              { text: 'General Reference', link: '/api/reference' },
              { text: 'Dimensions Reference', link: '/api/dimensions' },
              { text: 'LookupArrays Reference', link: '/api/lookuparrays' },
            ],
          },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/rafaqz/DimensionalData.jl' },
      
    ],
    footer: {
      message: 'Made with <a href="https://github.com/LuxDL/DocumenterVitepress.jl" target="_blank"><strong>DocumenterVitepress.jl</strong></a> by <a href="https://github.com/lazarusA" target="_blank"><strong>Lazaro Alonso</strong><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}. Released under the MIT License.`
    }
  }
})
