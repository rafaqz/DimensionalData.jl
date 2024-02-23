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
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  title: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
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
      { text: 'DimArrays', link: '/dimarrays' },
      { text: 'Selectors', link: '/selectors' },
      { text: 'Integrations',
        items: [
          { text: 'Plots and Makie', link: '/plots' },
          { text: 'Tables and DataFrames', link: '/tables' },
          { text: 'CUDA and GPUs', link: '/cuda' },
          { text: 'DiskArrays', link: '/diskarrays' },
          { text: 'Ecosystem', link: '/integrations' },
          { text: 'Extending DimensionalData', link: '/extending_dd' },
        ],
      },
      {
        text: `v${version}`,
        items: VERSIONS,
      },
    ],

    sidebar: 'REPLACE_ME_DOCUMENTER_VITEPRESS',

    socialLinks: [
      { icon: 'github', link: 'https://github.com/rafaqz/DimensionalData.jl' },

    ],
    footer: {
      message: 'Made with <a href="https://github.com/LuxDL/DocumenterVitepress.jl" target="_blank"><strong>DocumenterVitepress.jl</strong></a> by <a href="https://github.com/lazarusA" target="_blank"><strong>Lazaro Alonso</strong><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}. Released under the MIT License.`
    }
  }
})
