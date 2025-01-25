import{_ as r,c as e,ai as t,o as i}from"./chunks/framework.BhrVbS3f.js";const b=JSON.parse('{"title":"DiskArrays.jl compatibility","description":"","frontmatter":{},"headers":[],"relativePath":"diskarrays.md","filePath":"diskarrays.md","lastUpdated":null}'),l={name:"diskarrays.md"};function s(n,a,o,c,p,d){return i(),e("div",null,a[0]||(a[0]=[t('<h1 id="DiskArrays.jl-compatibility" tabindex="-1">DiskArrays.jl compatibility <a class="header-anchor" href="#DiskArrays.jl-compatibility" aria-label="Permalink to &quot;DiskArrays.jl compatibility {#DiskArrays.jl-compatibility}&quot;">​</a></h1><p><a href="https://github.com/meggart/DiskArrays.jl" target="_blank" rel="noreferrer">DiskArrays.jl</a> enables lazy, chunked application of:</p><ul><li><p>broadcast</p></li><li><p>reductions</p></li><li><p>iteration</p></li><li><p>generators</p></li><li><p>zip</p></li></ul><p>as well as caching chunks in RAM via <code>DiskArrays.cache(dimarray)</code>.</p><p>It is rarely used directly, but is present in most disk and cloud based spatial data packages in julia, including: <a href="https://github.com/yeesian/ArchGDAL.jl" target="_blank" rel="noreferrer">ArchGDAL.jl</a>, <a href="https://github.com/JuliaGeo/NetCDF.jl" target="_blank" rel="noreferrer">NetCDF.jl</a>, <a href="https://github.com/JuliaIO/Zarr.jl" target="_blank" rel="noreferrer">Zarr.jl</a>, <a href="https://github.com/Alexander-Barth/NCDatasets.jl" target="_blank" rel="noreferrer">NCDatasets.jl</a>, <a href="https://github.com/JuliaGeo/GRIBDatasets.jl" target="_blank" rel="noreferrer">GRIBDatasets.jl</a> and <a href="https://github.com/JuliaGeo/CommonDataModel.jl" target="_blank" rel="noreferrer">CommonDataModel.jl</a>.</p><p>The combination of DiskArrays.jl and DimensionalData.jl is Julia&#39;s answer to python&#39;s <a href="https://xarray.dev/" target="_blank" rel="noreferrer">xarray</a>. <a href="https://github.com/rafaqz/Rasters.jl" target="_blank" rel="noreferrer">Rasters.jl</a> and <a href="https://github.com/JuliaDataCubes/YAXArrays.jl" target="_blank" rel="noreferrer">YAXArrays.jl</a> are user-facing tools building on this combination.</p><p>They have no meaningful direct dependency relationships, but are intentionally designed to integrate via both adherence to Julia&#39;s <code>AbstractArray</code> interface, and by coordination during development of both packages.</p>',7)]))}const u=r(l,[["render",s]]);export{b as __pageData,u as default};
