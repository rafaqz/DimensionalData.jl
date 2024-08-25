import{_ as s,c as i,o as a,a6 as t}from"./chunks/framework.EpT1ISM2.js";const e="/DimensionalData.jl/previews/PR783/assets/jmmhsxu.iiL4UBgm.png",l="/DimensionalData.jl/previews/PR783/assets/ybmzrjc.BIa4VhRY.png",h="/DimensionalData.jl/previews/PR783/assets/veptoqy.CZKDtjAN.png",n="/DimensionalData.jl/previews/PR783/assets/izkfogt.nOjqWh1g.png",p="/DimensionalData.jl/previews/PR783/assets/yhxwiti.CBNkYhiq.png",k="/DimensionalData.jl/previews/PR783/assets/rcywifo.NnnTWDGw.png",b=JSON.parse('{"title":"Plots.jl","description":"","frontmatter":{},"headers":[],"relativePath":"plots.md","filePath":"plots.md","lastUpdated":null}'),r={name:"plots.md"},d=t(`<h1 id="plots-jl" tabindex="-1">Plots.jl <a class="header-anchor" href="#plots-jl" aria-label="Permalink to &quot;Plots.jl&quot;">​</a></h1><p>Plots.jl and Makie.jl functions mostly work out of the box on <code>AbstractDimArray</code>, although not with the same results - they choose to follow each packages default behaviour as much as possible.</p><p>This will plot a line plot with &#39;a&#39;, &#39;b&#39; and &#39;c&#39; in the legend, and values 1-10 on the labelled X axis:</p><p>Plots.jl support is deprecated, as development is moving to Makie.jl</p><h1 id="makie-jl" tabindex="-1">Makie.jl <a class="header-anchor" href="#makie-jl" aria-label="Permalink to &quot;Makie.jl&quot;">​</a></h1><p>Makie.jl functions also mostly work with <a href="/DimensionalData.jl/previews/PR783/api/reference#DimensionalData.AbstractDimArray"><code>AbstractDimArray</code></a> and will <code>permute</code> and <a href="/DimensionalData.jl/previews/PR783/object_modification#reorder"><code>reorder</code></a> axes into the right places, especially if <code>X</code>/<code>Y</code>/<code>Z</code>/<code>Ti</code> dimensions are used.</p><p>In Makie a <code>DimMatrix</code> will plot as a heatmap by default, but it will have labels and axes in the right places:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DimensionalData, CairoMakie</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">A </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">X</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Y</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:a</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:b</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:c</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(A; colormap</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:inferno</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+e+'" alt=""></p><p>Other plots also work, here DD ignores the axis order and instead favours the categorical variable for the X axis:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rainclouds</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(A)</span></span></code></pre></div><p><img src="'+l+`" alt=""></p><h2 id="Test-series-plots" tabindex="-1">Test series plots <a class="header-anchor" href="#Test-series-plots" aria-label="Permalink to &quot;Test series plots {#Test-series-plots}&quot;">​</a></h2><h3 id="default-colormap" tabindex="-1">default colormap <a class="header-anchor" href="#default-colormap" aria-label="Permalink to &quot;default colormap {#default-colormap}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">B </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">X</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Y</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:a</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:b</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:c</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:d</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:e</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:f</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:g</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:h</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:i</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:j</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">series</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(B)</span></span></code></pre></div><p><img src="`+h+'" alt=""></p><h3 id="A-different-colormap" tabindex="-1">A different colormap <a class="header-anchor" href="#A-different-colormap" aria-label="Permalink to &quot;A different colormap {#A-different-colormap}&quot;">​</a></h3><p>The colormap is controlled by the <code>color</code> argument, which can take as an input a named colormap, i.e. <code>:plasma</code> or a list of colours.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">series</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(B; color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:plasma</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+n+'" alt=""></p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">series</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(A; color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:red</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:blue</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:orange</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><p><img src="'+p+'" alt=""></p><h3 id="with-markers" tabindex="-1">with markers <a class="header-anchor" href="#with-markers" aria-label="Permalink to &quot;with markers {#with-markers}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">series</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(A; color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:red</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:blue</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:orange</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], markersize</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">15</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+k+'" alt=""></p><p>A lot more is planned for Makie.jl plots in future!</p>',26),o=[d];function E(g,c,y,F,C,m){return a(),i("div",null,o)}const f=s(r,[["render",E]]);export{b as __pageData,f as default};
