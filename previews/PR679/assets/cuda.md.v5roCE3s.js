import{_ as s,c as i,o as a,a7 as n}from"./chunks/framework.C7hxEoiY.js";const y=JSON.parse('{"title":"CUDA & GPUs","description":"","frontmatter":{},"headers":[],"relativePath":"cuda.md","filePath":"cuda.md","lastUpdated":null}'),h={name:"cuda.md"},t=n(`<h1 id="CUDA-and-GPUs" tabindex="-1">CUDA &amp; GPUs <a class="header-anchor" href="#CUDA-and-GPUs" aria-label="Permalink to &quot;CUDA &amp; GPUs {#CUDA-and-GPUs}&quot;">​</a></h1><p>Running regular julia code on GPUs is one of the most amazing things about the language. DimensionalData.jl leans into this as much as possible.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DimensionalData, CUDA</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Create a Float32 array to use on the GPU</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">A </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Float32, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">X</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Y</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2000.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Move the parent data to the GPU with \`modify\` and the \`CuArray\` constructor:</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cuA </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> modify</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(CuArray, A)</span></span></code></pre></div><p>The result of a GPU broadcast is still a DimArray:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> cuA2 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> cuA </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 2</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">╭───────────────────────────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">│ </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">×</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DimArray{Float32,</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">} │</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">├───────────────────────────────┴────────────────────────────── dims ┐</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  ↓ X Sampled{Float64} </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ForwardOrdered Regular Points,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  → Y Sampled{Float64} </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2000.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ForwardOrdered Regular Points</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">└────────────────────────────────────────────────────────────────────┘</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ↓ →  </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       2.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        3.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        4.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">       …  </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1998.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        1999.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        2000.0</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.69506</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.28405</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.989952</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.900394</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        1.73623</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.30427</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.98193</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    2.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.73591</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.929995</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.665742</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.345501</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        0.162919</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.81708</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       0.702944</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    3.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.24575</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.80455</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.78028</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.49097</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">         0.45804</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       0.224375</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      0.0197492</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    4.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  0.374026</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.91495</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.17645</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.995683</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        0.835288</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.54822</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       0.487601</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    5.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.17673</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.0557598</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  0.183637</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.90645</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">   …     </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.88058</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.23788</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.59705</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    6.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.57019</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.215049</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.9155</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">     0.982762</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        0.906838</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      0.1076</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        0.390081</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ⋮                                              ⋱                              </span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  995.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.48275</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.40409</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.37963</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    1.66622</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">         0.462981</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.4492</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        1.26917</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  996.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.88869</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.86174</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.298383</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.854739</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  …     </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.778222</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.42151</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.75568</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  997.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.88092</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.87436</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.285965</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.304688</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        1.32669</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       0.0599431</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">     0.134186</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  998.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.18035</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.61025</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.352614</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.75847</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">         0.464554</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.90309</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.30923</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  999.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.40584</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.83056</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    0.0804518</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  0.177423</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        1.20779</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       1.95217</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">       0.881149</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 1000.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">  1.41334</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.719974</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   0.479126</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">   1.92721</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">         0.0649391</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">     0.642908</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">      1.07277</span></span></code></pre></div><p>But the data is on the GPU:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">julia</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> typeof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">parent</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cuA2))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">CuArray{Float32, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, CUDA</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Mem</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">DeviceBuffer}</span></span></code></pre></div><h2 id="GPU-Integration-goals" tabindex="-1">GPU Integration goals <a class="header-anchor" href="#GPU-Integration-goals" aria-label="Permalink to &quot;GPU Integration goals {#GPU-Integration-goals}&quot;">​</a></h2><p>DimensionalData.jl has two GPU-related goals:</p><ol><li>Work seamlessly with Base julia broadcasts and other operations that already</li></ol><p>work on GPU.</p><ol><li>Work as arguments to custom GPU kernel funcions.</li></ol><p>This means any <code>AbstractDimArray</code> must be automatically moved to the gpu and its fields converted to GPU friendly forms whenever required, using <a href="https://github.com/JuliaGPU/Adapt.jl" target="_blank" rel="noreferrer">Adapt.jl</a>).</p><ul><li><p>The array data must converts to the correct GPU array backend when <code>Adapt.adapt(dimarray)</code> is called.</p></li><li><p>All DimensionalData.jl objects, except the actual parent array, need to be immutable <code>isbits</code> or convertable to them. This is one reason DimensionalData.jl uses <code>rebuild</code> and a functional style, rather than in-place modification of fields.</p></li><li><p>Symbols need to be moved to the type system <code>Name{:layer_name}()</code> replaces <code>:layer_name</code></p></li><li><p>Metadata dicts need to be stripped, they are often too difficult to convert, and not needed on GPU.</p></li></ul><p>As an example, <a href="https://github.com/cesaraustralia/DynamicGrids.jl" target="_blank" rel="noreferrer">DynamicGrids.jl</a> uses <code>AbstractDimArray</code> for auxiliary model data that are passed into <a href="https://github.com/JuliaGPU/KernelAbstractions.jl" target="_blank" rel="noreferrer">KernelAbstractions.jl</a>/ <a href="https://github.com/JuliaGPU/CUDA.jl" target="_blank" rel="noreferrer">CUDA.jl</a> kernels.</p>`,15),l=[t];function k(p,e,r,d,F,C){return a(),i("div",null,l)}const o=s(h,[["render",k]]);export{y as __pageData,o as default};
