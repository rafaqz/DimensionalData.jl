```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "DimensionalData.jl"
  text: "Julia datasets with named dimensions"
  tagline: High performance named indexing for Julia
  image:
    src: 'logoDD.png'
  actions:
    - theme: brand
      text: Getting Started
      link: /basics
    - theme: alt
      text: API reference
      link: /api/reference
    - theme: alt
      text: View on Github
      link: https://github.com/rafaqz/DimensionalData.jl
features:
  - icon: <img width="64" height="64" src="https://img.icons8.com/nolan/64/3d-scale.png" alt="3d-scale"/>
    title: Intelligent indexing
    details: DimensionalData.jl provides no-cost abstractions for named indexing, and fast index lookups.
    link: /selectors
  - icon: <img width="64" height="64" src="https://img.icons8.com/nolan/64/grid.png" alt="grid"/>
    title: Powerful Array manipulation
    details: broadcast, reduce, permutedims, and <font color="orange">groupby</font> operations.
    link: /groupby
  - icon: <img width="64" height="64" src="https://img.icons8.com/nolan/64/layers.png" alt="layers"/>
    title: Seamlessly integrated with the julia ecosystem
    details: Works with most methods that accept a regular `Array`. If a method accepts numeric indices or <strong>dims=X</strong> in base, you should be able to use DimensionalData.jl <strong>dims</strong>.
---
```
