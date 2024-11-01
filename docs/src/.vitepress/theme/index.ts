// .vitepress/theme/index.ts
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import VersionPicker from "./VersionPicker.vue"
import './style.css'

// taken from
// https://github.com/MakieOrg/Makie.jl/blob/master/docs/src/.vitepress/theme/index.ts

export default {
  extends: DefaultTheme,
  enhanceApp({ app, router, siteData }) {
      enhanceAppWithTabs(app);
      app.component('VersionPicker', VersionPicker);
    }
} satisfies Theme;