using Colors
using CairoMakie
CairoMakie.activate!()
mkpath(joinpath(@__DIR__, "./src/public/"))

rpyz = [Rect3f(Vec3f(0, j-0.8,k), Vec3f(0.1, 0.8,0.8))
    for j in 1:7 for k in 1:7]
rmyz = [Rect3f(Vec3f(j-0.8, 0,k), Vec3f(0.8, 0.1,0.8))
    for j in 1:7 for k in 1:7]

colors = ["#ff875f", "#0087d7", "#5fd7ff", "#ff5f87", "#b2b2b2", "#d75f00", "#00afaf"]
fig = Figure(; size=(500,500),
    backgroundcolor=:transparent,
    fonts = (; regular = "Barlow"))
ax = LScene(fig[1,1]; show_axis=false)

wireframe!.(ax, rpyz; color = colors[3], transparency=true) # shading=NoShading # bug!
mesh!.(ax, rmyz; color=colors[1], transparency=true, shading=NoShading)

meshscatter!(ax, [Point3f(0.1,0.1,0.8), Point3f(0.1+7,0.1,0.8),
    Point3f(0.1,0.1+7,0.8), Point3f(0.1+7,0.1+7,0.8)]; color = colors[4],
    markersize=0.25, shading=FastShading)

lines!(ax, [Point3f(0.1,0.1,0.8), Point3f(0.1+7,0.1,0.8), Point3f(0.1+7,0.1+7,0.8), 
    Point3f(0.1,0.1+7,0.8), Point3f(0.1,0.1,0.8)]; color = colors[4],
    linewidth=2, transparency=true)
meshscatter!(ax, Point3f(4,4,-0.01); color=:transparent)
meshscatter!(ax, [Point3f(0.1,0.1,8), Point3f(0.1+7,0.1,8), Point3f(0.1,0.1+7,8), Point3f(0.1+7,0.1+7,8)]; color = colors[2], markersize=0.2, shading=FastShading)

lines!(ax, [ Point3f(0.1+7,0.1,8), Point3f(0.1+7,0.1+7,8), 
    Point3f(0.1,0.1+7,8),
    ];
    color = colors[2],
    linewidth=2, transparency=true)
save(joinpath(@__DIR__, "./src/public/logoDD.png"), fig)
fig