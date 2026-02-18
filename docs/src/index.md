```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "DimensionalData.jl"
  text: "Julia datasets with named dimensions"
  tagline: High performance named indexing for Julia
  image:
    src: 'https://private-user-images.githubusercontent.com/32276930/362387885-fae06b7a-ed02-4acb-8d0d-de0121e7b6f6.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjQ4NjU2NzMsIm5iZiI6MTcyNDg2NTM3MywicGF0aCI6Ii8zMjI3NjkzMC8zNjIzODc4ODUtZmFlMDZiN2EtZWQwMi00YWNiLThkMGQtZGUwMTIxZTdiNmY2LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDA4MjglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwODI4VDE3MTYxM1omWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWE1ZjM2M2VlMjE1NTE0NDY5ZjVhMzBhYzUyYjAzZmFlZjM0NmE4YTVhZDhiY2MxOWIzNTg1YjQyZTBhMDBmYjUmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.hKWDoaM7OLtbzNfi5rSHGDAhJ9wEvBo42eLowpGbNpo'
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
  - title: Intelligent indexing
    details: DimensionalData.jl provides no-cost abstractions for named indexing, and fast index lookups.
    link: /selectors
  - title: Powerful Array manipulation
    details: broadcast, reduce, permutedims, and groupby operations.
    link: /groupby
  - title: Seamlessly integrated with the julia ecosystem
    details: Works with most methods that accept a regular Array. If a method accepts numeric indices or dims=X in base, you should be able to use DimensionalData.jl dims.
    link: /integrations
---
```
