import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";
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
        { text: 'Extending DimensionalData', link: '/extending_dd' },
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
    logo: { src: '/logo.png', width: 24, height: 24 },
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
