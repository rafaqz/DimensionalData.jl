import{_ as t,c as i,a4 as r,o as e}from"./chunks/framework.BKx4bRZJ.js";const m=JSON.parse('{"title":"DiskArrays.jl compatibility","description":"","frontmatter":{},"headers":[],"relativePath":"diskarrays.md","filePath":"diskarrays.md","lastUpdated":null}'),s={name:"diskarrays.md"};function l(n,a,o,d,p,c){return e(),i("div",null,a[0]||(a[0]=[r('<h1 id="DiskArrays.jl-compatibility" tabindex="-1">DiskArrays.jl compatibility <a class="header-anchor" href="#DiskArrays.jl-compatibility" aria-label="Permalink to &quot;DiskArrays.jl compatibility {#DiskArrays.jl-compatibility}&quot;">​</a></h1><p><a href="https://github.com/meggart/DiskArrays.jl" target="_blank" rel="noreferrer">DiskArrays.jl</a> enables lazy, chunked application of:</p><ul><li><p>broadcast</p></li><li><p>reductions</p></li><li><p>iteration</p></li><li><p>generators</p></li><li><p>zip</p></li></ul><p>It is rarely used directly, but is present in most disk and cloud based spatial data packages in julia, including: ArchGDAL.jl, NetCDF.jl, Zarr.jl, NCDatasets.lj, GRIBDatasets.jl and CommonDataModel.jl</p><p>The combination of DiskArrays.jl and DimensionalData.jl is Julias answer to pythons <a href="https://xarray.dev/" target="_blank" rel="noreferrer">xarray</a>. Rasters.jl and YAXArrays.jl are user-facing tools building on this combination.</p><p>They have no direct dependency relationships, with but are intentionally designed to integrate via both adherence to Julia&#39;s <code>AbstractArray</code> interface, and by coordination during development of both packages.</p>',6)]))}const h=t(s,[["render",l]]);export{m as __pageData,h as default};
