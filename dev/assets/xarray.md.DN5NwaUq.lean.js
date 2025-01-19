import{_ as e,c as t,a4 as s,o as r}from"./chunks/framework.B_OTBNpe.js";const c=JSON.parse('{"title":"Xarray and PythonCall.jl","description":"","frontmatter":{},"headers":[],"relativePath":"xarray.md","filePath":"xarray.md","lastUpdated":null}'),i={name:"xarray.md"};function n(l,a,o,h,p,d){return r(),t("div",null,a[0]||(a[0]=[s(`<h1 id="Xarray-and-PythonCall.jl" tabindex="-1">Xarray and PythonCall.jl <a class="header-anchor" href="#Xarray-and-PythonCall.jl" aria-label="Permalink to &quot;Xarray and PythonCall.jl {#Xarray-and-PythonCall.jl}&quot;">​</a></h1><p>In the Python ecosystem <a href="https://xarray.dev" target="_blank" rel="noreferrer">Xarray</a> is by far the most popular package for working with multidimensional labelled arrays. The main data structures it provides are:</p><ul><li><p><a href="https://docs.xarray.dev/en/stable/user-guide/data-structures.html#dataarray" target="_blank" rel="noreferrer">DataArray</a>, analagous to <code>DimArray</code>.</p></li><li><p><a href="https://docs.xarray.dev/en/stable/user-guide/data-structures.html#dataset" target="_blank" rel="noreferrer">Dataset</a>, analagous to <code>DimStack</code>.</p></li></ul><p>DimensionalData integrates with <a href="https://juliapy.github.io/PythonCall.jl/stable/" target="_blank" rel="noreferrer">PythonCall.jl</a> to allow converting these Xarray types to their DimensionalData equivalent:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">import</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PythonCall</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> pyconvert</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">my_dimarray </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pyconvert</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(DimArray, my_dataarray)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">my_dimstack </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pyconvert</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(DimStack, my_dataset)</span></span></code></pre></div><p>Note that:</p><ul><li><p>The current implementation will make a copy of the underlying arrays.</p></li><li><p>Python stores arrays in row-major order whereas Julia stores them in column-major order, hence the dimensions on a converted <code>DimArray</code> will be in reverse order from the original <code>DataArray</code>. This is done to ensure that the &#39;fast axis&#39; to iterate over is the same dimension in both Julia and Python.</p></li></ul>`,7)]))}const k=e(i,[["render",n]]);export{c as __pageData,k as default};
