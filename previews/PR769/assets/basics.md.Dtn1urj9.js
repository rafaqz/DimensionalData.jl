import{_ as s,c as i,o as a,a6 as n}from"./chunks/framework.D4i0NpFI.js";const c=JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"basics.md","filePath":"basics.md","lastUpdated":null}'),h={name:"basics.md"},l=n(`<h2 id="installation" tabindex="-1">Installation <a class="header-anchor" href="#installation" aria-label="Permalink to &quot;Installation&quot;">​</a></h2><p>If you want to use this package you need to install it first. You can do it using the following commands:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ] </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># &#39;]&#39; should be pressed</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add DimensionalData</span></span></code></pre></div><p>or</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Pkg</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">add</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;DimensionalData&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Additionally, it is recommended to check the version that you have installed with the status command.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> status DimensionalData</span></span></code></pre></div><h2 id="basics" tabindex="-1">Basics <a class="header-anchor" href="#basics" aria-label="Permalink to &quot;Basics&quot;">​</a></h2><p>Start using the package:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DimensionalData</span></span></code></pre></div><p>and create your first DimArray</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> A </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> DimArray</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), (a</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, b</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">╭─────────────────────────╮</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">│ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">4</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">×</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">5</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> DimArray{Float64,2}</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> │</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">├─────────────────────────┴─────────────────────── dims ┐</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">  ↓ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">a</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Sampled{Int64} </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">1:4</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Regular</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Points</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">,</span></span>
<span class="line"><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">  → </span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">b</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Sampled{Int64} </span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">1:5</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Regular</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Points</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">└───────────────────────────────────────────────────────┘</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> ↓</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;"> →</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">  1</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">         2</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">          3</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">         4</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">         5</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> 1</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    0.541806  0.0282382  0.762794  0.844547  0.919763</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> 2</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    0.300768  0.247683   0.388243  0.95636   0.383632</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> 3</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    0.70597   0.599558   0.803192  0.675435  0.487578</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> 4</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    0.93479   0.624685   0.774731  0.216524  0.102405</span></span></code></pre></div><p>or</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> C </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> DimArray</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Int8, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), (alpha</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&#39;a&#39;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&#39;j&#39;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">╭─────────────────────────────╮</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">│ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">10-element </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">DimArray{Int8,1}</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> │</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">├─────────────────────────────┴──────────────── dims ┐</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">  ↓ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">alpha</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Categorical{Char} </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">&#39;a&#39;:1:&#39;j&#39;</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">└────────────────────────────────────────────────────┘</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;a&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  112</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;b&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   85</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;c&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  -86</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;d&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  123</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;e&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   95</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;f&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   59</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;g&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  -91</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;h&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   55</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;i&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  -78</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> &#39;j&#39;</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  -15</span></span></code></pre></div><p>or something a little bit more complicated:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> data </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Int8, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.|&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> abs</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">2×10×3 Array{Int8, 3}:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">[:, :, 1] =</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  65  110   71  108  76  15  120   65  121  126</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> 125   78  118  101  11  32   87  108   49  115</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">[:, :, 2] =</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> 106  84  74  80   9   26  35  74  28  47</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  87   1  42  54  15  107  77  23  89  34</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">[:, :, 3] =</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> 65  66  113  1  123  16  69  104  -128  26</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> 25  13   29  1   21  72  24   48    51  88</span></span></code></pre></div><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> B </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> DimArray</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(data, (channel</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:left</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:right</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], time</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, iter</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">╭─────────────────────────╮</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">│ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">2</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">×</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">10</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">×</span><span style="--shiki-light:#5fd7ff;--shiki-dark:#5fd7ff;">3</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> DimArray{Int8,3}</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> │</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">├─────────────────────────┴─────────────────────────────── dims ┐</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">  ↓ </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">channel</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Categorical{Symbol} </span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">[:left, :right]</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">,</span></span>
<span class="line"><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">  → </span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">time   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Sampled{Int64} </span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">1:10</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Regular</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Points</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">,</span></span>
<span class="line"><span style="--shiki-light:#5fd7ff;--shiki-dark:#5fd7ff;">  ↗ </span><span style="--shiki-light:#5fd7ff;--shiki-dark:#5fd7ff;">iter   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> Sampled{Int64} </span><span style="--shiki-light:#5fd7ff;--shiki-dark:#5fd7ff;">1:3</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> ForwardOrdered</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Regular</span><span style="--shiki-light:#808080;--shiki-dark:#808080;"> Points</span></span>
<span class="line"><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">└───────────────────────────────────────────────────────────────┘</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">[</span><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">:</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">, </span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">:</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">, </span><span style="--shiki-light:#5fd7ff;--shiki-dark:#5fd7ff;">1</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">]</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;"> ↓</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;"> →</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">        1</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    2</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    3</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    4</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">   5</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">   6</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    7</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    8</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">    9</span><span style="--shiki-light:#0087d7;--shiki-dark:#0087d7;">   10</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">  :left</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    65  110   71  108  76  15  120   65  121  126</span></span>
<span class="line"><span style="--shiki-light:#ff875f;--shiki-dark:#ff875f;">  :right</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  125   78  118  101  11  32   87  108   49  115</span></span></code></pre></div>`,21),t=[l];function k(e,p,d,r,g,y){return a(),i("div",null,t)}const E=s(h,[["render",k]]);export{c as __pageData,E as default};
