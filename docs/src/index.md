```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "DimensionalData.jl"
  text: "Julia datasets with named dimensions"
  tagline: High performance named indexing for Julia
  image:
    src: 'https://private-user-images.githubusercontent.com/32276930/362385498-84c99edd-2971-483e-8d09-589a6e0c63ba.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjQ4NjUxNzEsIm5iZiI6MTcyNDg2NDg3MSwicGF0aCI6Ii8zMjI3NjkzMC8zNjIzODU0OTgtODRjOTllZGQtMjk3MS00ODNlLThkMDktNTg5YTZlMGM2M2JhLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDA4MjglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwODI4VDE3MDc1MVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTNhZDU5MDllMjA4Nzk2YWVlZTZiNGZlNzQ3MzYzMjA4MmY4NzQ2MzYxNmI2NzdmZWE0YzczZjY4ZjU4MDRmZjEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.jAOORcfEugQH01_KK_oOg4zVE74TBKr680oZ8Wvhhj4'
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
---
```
