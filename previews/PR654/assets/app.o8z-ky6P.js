import{j as o,a7 as p,a8 as u,a9 as c,aa as l,ab as f,ac as d,ad as m,ae as h,af as A,ag as g,Y as v,d as P,u as w,l as y,z as C,ah as R,ai as _,aj as b,a6 as E}from"./chunks/framework.9_6EAP9Q.js";import{R as j}from"./chunks/theme.JnHomzlQ.js";function i(e){if(e.extends){const a=i(e.extends);return{...a,...e,async enhanceApp(t){a.enhanceApp&&await a.enhanceApp(t),e.enhanceApp&&await e.enhanceApp(t)}}}return e}const s=i(j),D=P({name:"VitePressApp",setup(){const{site:e,lang:a,dir:t}=w();return y(()=>{C(()=>{document.documentElement.lang=a.value,document.documentElement.dir=t.value})}),e.value.router.prefetchLinks&&R(),_(),b(),s.setup&&s.setup(),()=>E(s.Layout)}});async function T(){const e=O(),a=L();a.provide(u,e);const t=c(e.route);return a.provide(l,t),a.component("Content",f),a.component("ClientOnly",d),Object.defineProperties(a.config.globalProperties,{$frontmatter:{get(){return t.frontmatter.value}},$params:{get(){return t.page.value.params}}}),s.enhanceApp&&await s.enhanceApp({app:a,router:e,siteData:m}),{app:a,router:e,data:t}}function L(){return h(D)}function O(){let e=o,a;return A(t=>{let n=g(t),r=null;return n&&(e&&(a=n),(e||a===n)&&(n=n.replace(/\.js$/,".lean.js")),r=v(()=>import(n),__vite__mapDeps([]))),o&&(e=!1),r},s.NotFound)}o&&T().then(({app:e,router:a,data:t})=>{a.go().then(()=>{p(a.route,t.site),e.mount("#app")})});export{T as createApp};
function __vite__mapDeps(indexes) {
  if (!__vite__mapDeps.viteFileDeps) {
    __vite__mapDeps.viteFileDeps = []
  }
  return indexes.map((i) => __vite__mapDeps.viteFileDeps[i])
}
