import{_ as o,C as p,o as u,c,an as d,E as a,w as i,j as s,a as l}from"./chunks/framework.DlpU30wy.js";const y=JSON.parse('{"title":"Getters","description":"DimensionalData.jl getter methods - retrieve dimensions, lookups, metadata and values from DimArrays and DimStacks in Julia","frontmatter":{"description":"DimensionalData.jl getter methods - retrieve dimensions, lookups, metadata and values from DimArrays and DimStacks in Julia"},"headers":[],"relativePath":"get_info.md","filePath":"get_info.md","lastUpdated":null}'),r={name:"get_info.md"};function h(g,n,k,m,b,v){const e=p("PluginTabsTab"),t=p("PluginTabs");return u(),c("div",null,[n[24]||(n[24]=d("",6)),a(t,null,{default:i(()=>[a(e,{label:"dims"},{default:i(()=>[...n[0]||(n[0]=[s("p",null,[s("code",null,"dims"),l(" retrieves dimensions from any object that has them.")],-1),s("p",null,[l("What makes it so useful is that you can filter which dimensions you want, and specify in what order, using any "),s("code",null,"Dimension"),l(", "),s("code",null,"Type{Dimension}"),l(" or "),s("code",null,"Symbol"),l(".")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"dims(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, Y)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, Y())")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, :Y)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, (X,))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, (Y, X))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, reverse(dims(A)))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isregular)")])])])],-1)])]),_:1}),a(e,{label:"otherdims"},{default:i(()=>[...n[1]||(n[1]=[s("p",null,[s("code",null,"otherdims"),l(" is just like "),s("code",null,"dims"),l(" but returns whatever "),s("code",null,"dims"),l(" would "),s("em",null,"not"),l(" return from the same query.")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"otherdims(A, Y)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, Y())")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, :Y)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, (X,))")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, (Y, X))")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isregular)")])])])],-1)])]),_:1}),a(e,{label:"lookup"},{default:i(()=>[...n[2]||(n[2]=[s("p",null,[l("Get all the "),s("code",null,"Lookup"),l(" in an object")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"lookup(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"lookup(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"lookup(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"lookup(dims(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"val"},{default:i(()=>[...n[3]||(n[3]=[s("p",null,[s("code",null,"val"),l(" is used where there is an unambiguous single value:")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"val(X(7))")]),l(`
`),s("span",{class:"line"},[s("span",null,"val(At(10.5))")])])])],-1)])]),_:1}),a(e,{label:"order"},{default:i(()=>[...n[4]||(n[4]=[s("p",null,[l("Get the order of a "),s("code",null,"Lookup"),l(", or a "),s("code",null,"Tuple"),l(" from a "),s("code",null,"DimArray"),l(" or "),s("code",null,"DimTuple"),l(".")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"order(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"order(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"order(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"order(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"sampling"},{default:i(()=>[...n[5]||(n[5]=[s("p",null,[l("Get the sampling of a "),s("code",null,"Lookup"),l(", or a "),s("code",null,"Tuple"),l(" from a "),s("code",null,"DimArray"),l(" or "),s("code",null,"DimTuple"),l(".")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"sampling(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"sampling(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"sampling(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"sampling(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"span"},{default:i(()=>[...n[6]||(n[6]=[s("p",null,[l("Get the span of a "),s("code",null,"Lookup"),l(", or a "),s("code",null,"Tuple"),l(" from a "),s("code",null,"DimArray"),l(" or "),s("code",null,"DimTuple"),l(".")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"span(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"span(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"span(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"span(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"locus"},{default:i(()=>[...n[7]||(n[7]=[s("p",null,[l("Get the locus of a "),s("code",null,"Lookup"),l(", or a "),s("code",null,"Tuple"),l(" from a "),s("code",null,"DimArray"),l(" or "),s("code",null,"DimTuple"),l(".")],-1),s("p",null,[l("("),s("code",null,"locus"),l(" is our term for distinguishing if an lookup value specifies the start, center, or end of an interval)")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"locus(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"locus(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"locus(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"locus(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"bounds"},{default:i(()=>[...n[8]||(n[8]=[s("p",null,[l("Get the bounds of each dimension. This is different for "),s("code",null,"Points"),l(" and "),s("code",null,"Intervals"),l(" - the bounds for points of a "),s("code",null,"Lookup"),l(" are simply "),s("code",null,"(first(l), last(l))"),l(".")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"bounds(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"bounds(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"bounds(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"bounds(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"intervalbounds"},{default:i(()=>[...n[9]||(n[9]=[s("p",null,"Get the bounds of each interval along a dimension.",-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"intervalbounds(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"intervalbounds(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"intervalbounds(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"intervalbounds(lookup(A, Y))")])])])],-1)])]),_:1}),a(e,{label:"extent"},{default:i(()=>[...n[10]||(n[10]=[s("p",null,[s("a",{href:"https://github.com/rafaqz/Extent",target:"_blank",rel:"noreferrer"},"Extents.jl"),l(" provides an "),s("code",null,"Extent"),l(" object that combines the names of dimensions with their bounds.")],-1),s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"using Extents: extent")]),l(`
`),s("span",{class:"line"},[s("span",null,"extent(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"extent(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"extent(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"extent(dims(A, Y))")])])])],-1)])]),_:1})]),_:1}),n[25]||(n[25]=d("",3)),a(t,null,{default:i(()=>[a(e,{label:"issampled"},{default:i(()=>[...n[11]||(n[11]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"issampled(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"issampled(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"issampled(A, Y)")]),l(`
`),s("span",{class:"line"},[s("span",null,"issampled(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, issampled)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, issampled)")]),l(`
`),s("span",{class:"line"},[s("span",null,"lookup(A, issampled)")])])])],-1)])]),_:1}),a(e,{label:"iscategorical"},{default:i(()=>[...n[12]||(n[12]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"iscategorical(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscategorical(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscategorical(dims(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscategorical(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, iscategorical)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, iscategorical)")]),l(`
`),s("span",{class:"line"},[s("span",null,"lookup(A, iscategorical)")])])])],-1)])]),_:1}),a(e,{label:"iscyclic"},{default:i(()=>[...n[13]||(n[13]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"iscyclic(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscyclic(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscyclic(dims(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscyclic(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, iscyclic)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, iscyclic)")])])])],-1)])]),_:1}),a(e,{label:"isordered"},{default:i(()=>[...n[14]||(n[14]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isordered(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isordered(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isordered(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isordered(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isordered)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isordered)")])])])],-1)])]),_:1}),a(e,{label:"isforward"},{default:i(()=>[...n[15]||(n[15]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isforward(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isforward(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isforward(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isforward)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isforward)")])])])],-1)])]),_:1}),a(e,{label:"isreverse"},{default:i(()=>[...n[16]||(n[16]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isreverse(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isreverse(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isreverse(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isreverse)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isreverse)")])])])],-1)])]),_:1}),a(e,{label:"isintervals"},{default:i(()=>[...n[17]||(n[17]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isintervals(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isintervals(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isintervals(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isintervals(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isintervals)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isintervals)")])])])],-1)])]),_:1}),a(e,{label:"ispoints"},{default:i(()=>[...n[18]||(n[18]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"ispoints(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"ispoints(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"ispoints(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"ispoints(lookup(A, Y))")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, ispoints)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, ispoints)")])])])],-1)])]),_:1}),a(e,{label:"isregular"},{default:i(()=>[...n[19]||(n[19]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isregular(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isregular(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isregular(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isregular)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isregular)")])])])],-1)])]),_:1}),a(e,{label:"isexplicit"},{default:i(()=>[...n[20]||(n[20]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isexplicit(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isexplicit(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isexplicit(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isexplicit)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isexplicit)")])])])],-1)])]),_:1}),a(e,{label:"isstart"},{default:i(()=>[...n[21]||(n[21]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isstart(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isstart(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isstart(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isstart)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isstart)")])])])],-1)])]),_:1}),a(e,{label:"iscenter"},{default:i(()=>[...n[22]||(n[22]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"iscenter(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscenter(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"iscenter(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, iscenter)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, iscenter)")])])])],-1)])]),_:1}),a(e,{label:"isend"},{default:i(()=>[...n[23]||(n[23]=[s("div",{class:"language-@ansi vp-adaptive-theme"},[s("button",{title:"Copy Code",class:"copy"}),s("span",{class:"lang"},"@ansi"),s("pre",{class:"shiki shiki-themes github-light github-dark vp-code",tabindex:"0"},[s("code",null,[s("span",{class:"line"},[s("span",null,"isend(A)")]),l(`
`),s("span",{class:"line"},[s("span",null,"isend(dims(A))")]),l(`
`),s("span",{class:"line"},[s("span",null,"isend(A, X)")]),l(`
`),s("span",{class:"line"},[s("span",null,"dims(A, isend)")]),l(`
`),s("span",{class:"line"},[s("span",null,"otherdims(A, isend)")])])])],-1)])]),_:1})]),_:1})])}const f=o(r,[["render",h]]);export{y as __pageData,f as default};
