@safetestset "Plots.jl" begin

using Plots
using StatsPlots
using DimensionalData, Test, Dates
import Distributions
using Unitful, Unitful.DefaultSymbols

@testset "Plots.jl" begin


using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

A1 = rand(Distributions.Normal(), 20)
ref = (Ti(Sampled(1:1; order=ForwardOrdered(), span=Regular(Day(1)), sampling=Points())),)
da1_regular = DimArray(A1, X(1:50:1000); name=:Normal, refdims=ref)
da1_noindex = DimArray(A1, X(); name=:Normal, refdims=ref)
da1_categorical = DimArray(A1, X('A':'T'); name=:Normal, refdims=ref)
da1_categorical_symbol = DimArray(A1, X(Symbol.('A':'T')); name=:Normal, refdims=ref)
da1_z = DimArray(A1, Z(1:50:1000); name=:Normal, refdims=ref)

# For manual testing
da1 = da1_categorical

for da in (da1_regular, da1_noindex, da1_categorical, da1_categorical_symbol, da1_z)
    for da1 in (da, reverse(da))
        # Plots
        plot(da1)
        bar(da1)
        sticks(da1)
        histogram(da1)
        stephist(da1)
        barhist(da1)
        scatterhist(da1)
        histogram2d(da1)
        hline(da1)
        vline(da1)
        plot(da1; seriestype=:line)
        plot(da1; seriestype=:path)
        plot(da1; seriestype=:shape)
        plot(da1; seriestype=:steppost)
        plot(da1; seriestype=:steppre)
        plot(da1; seriestype=:scatterbins)
        # StatsPlots
        dotplot(da1)
        boxplot(da1)
        violin(da1)
        # broken in StatsPlots marginalhist(da1)
        ea_histogram(da1)
        density(da1)
    end
end

A2 = rand(Distributions.Normal(), 40, 20)
da2_regular = DimArray(A2, (X(1:10:400), Y(1:5:100)); name=:Normal)
da2_noindex = DimArray(A2, (X(), Y()); name=:Normal)
da2_ni_r = DimArray(A2, (X(), Y(1:5:100)); name=:Normal)
da2_r_ni = DimArray(A2, (X(1:10:400), Y()); name=:Normal)
da2_c_c = DimArray(A2, (X('A':'h'), Y('a':'t')); name=:Normal)
da2_XY = DimArray(A2, (X(1:10:400), Y(1:5:100)); name=:Normal)
da2_YX = DimArray(A2, (Y(1:10:400), X(1:5:100)); name=:Normal)
da2_ZY = DimArray(A2, (Z(1:10:400), Y(1:5:100)); name=:Normal)
da2_XTi = DimArray(A2, (X(1:10:400), Ti(Date(1):Year(5):Date(100))); name=:Normal)
da2_other = DimArray(A2, (X=1:10:400, other=1:5:100); name=:Normal)

# For manual testing
da2 = da2_XTi
da2 = da2_c_c
da2 = da2_other

for da in (da2_regular, da2_noindex, da2_ni_r, da2_r_ni, da2_c_c, da2_YX, da2_XY, da2_ZY)
    for da2 in (da, reverse(da, dims=first(dims(da))), reverse(da, dims=first(dims(da))))
        # Plots
        plot(da2)
        bar(da2)
        violin(da2)
        boxplot(da2)
        sticks(da2)
        histogram(da2)
        stephist(da2)
        barhist(da2)
        scatterhist(da2)
        histogram2d(da2)
        hline(da2)
        vline(da2)
        plot(da2; seriestype=:line)
        heatmap(da2)
        contour(da2)
        wireframe(da2)
        # StatsPlots
        density(da2)
        dotplot(da2)
        boxplot(da2)
        violin(da2)
        ea_histogram(da2)
    end
end

A3 = rand(Distributions.Normal(), 40, 20, 10)
da3_regular = DimArray(A3, (X(1:10:400), Y(1:5:100), Z(1:2:20)); name=:Normal)
da3_noindex = DimArray(A3, (X(), Y(), Z()); name=:Normal)
da3_ni_r_ni = DimArray(A3, (X(), Y(1:5:100), Z()); name=:Normal)
da3_c_c_c = DimArray(A3, (X('A':'h'), Y('a':'t'), Z('0':'9')); name=:Normal)
da3_XYZ = DimArray(A3, (X(1:10:400), Y(1:5:100), Z(1:10:100)); name=:Normal)
da3_XTiZ = DimArray(A3, (X(1:10:400), Ti(1s:5s:100s), Z(1:10:100)); name=:Normal)
da3_other = DimArray(A3, (X=1:10:400, other=1:5:100, anothing=NoLookup()); name=:Normal)
da3 = da3_other
da3 = da3_XYZ
da3 = da3_XTiZ

for da in (da3_regular, da3_noindex, da3_ni_r_ni, da3_c_c_c, da3_XYZ, da3_XTiZ, da3_other)
    for da3 in (da, reverse(da, dims=first(dims(da))), reverse(da, dims=first(dims(da))))
        # Plots
        @test_throws ArgumentError plot(da3)
        # bar(da3)
        violin(da3)
        boxplot(da3)
        @test_throws ArgumentError sticks(da3)
        @test_throws ArgumentError histogram(da3)
        @test_throws ArgumentError stephist(da3)
        @test_throws ArgumentError barhist(da3)
        @test_throws ArgumentError scatterhist(da3)
        @test_throws ArgumentError histogram2d(da3)
        hline(da3)
        vline(da3)
        @test_throws ArgumentError plot(da3; seriestype=:line)
        @test_throws ArgumentError heatmap(da3)
        @test_throws ArgumentError contour(da3)
        @test_throws ArgumentError wireframe(da3)
        # StatsPlots
        @test_throws ArgumentError density(da3)
        dotplot(da3)
        boxplot(da3)
        violin(da3)
        @test_throws ArgumentError ea_histogram(da3)
    end
end

# Not sure how recipes work for this
# andrewsplot(da2)

# TODO handle everything

# These don't seem to work for plot(parent(da2))
# path3d(da2)
# hexbin(parent(da1))
# plot(da2; seriestype=:histogram3d)

# Crashes GR
# groupedbar(parent(da2))

# surface(da2)
# plot(da2; seriestype=:bins2d)
# plot(da2; seriestype=:volume)
# plot(da2; seriestype=:stepbins)
# plot(parent(da2); seriestype=:barbins)
# plot(parent(da2); seriestype=:contour3d)
# pie(da2)
#
# Crashes GR for some reason
# im2 = RGB24.(rand(10, 10))
# da_im2 = DimArray(im2, (X(10:10:100), Y(10:10:100)), "Image")
# da_im2 |> plot

end
end #  end of plots tests

@safetestset "Makie" begin
using DimensionalData, Test, Dates
using AlgebraOfGraphics
using CairoMakie
using ColorTypes
using Unitful, Unitful.DefaultSymbols
import Distributions
import DimensionalData as DD


using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

@testset "1D plots" begin 
    dd_vec = DimArray((1:5).^2, Ti(1:5), name=:test)
    dd_range = DimArray(1:5, Ti(1:5), name=:test) # test for #949
    dd_vec_mis = DimArray([missing, 2, 3, 4, 5], Ti('A':'E'), name= "test")
    dd_vec_uni = DimArray(.√(1:5) .* m, Ti((1:5) .* F), name= "test")

    fig = Figure()
    @test_throws MethodError lines(fig, dd_vec) # error as in lines(fig, 1:10)
    ax, plt = lines(fig[1,1], dd_vec)
    @test_throws ErrorException lines(fig[1,1], dd_vec)
    lines!(ax, dd_vec)
    
    fig = Figure()
    @test lines(fig[1,1][1,1], dd_vec) isa Makie.AxisPlot

    f = Figure()
    ga = f[1, 1] = GridLayout()
    @test lines(ga[1, 1], dd_vec) isa Makie.AxisPlot
  
    for dd_i in (dd_vec, dd_vec_uni, dd_range)
        for obs in (Observable, identity)
            for plot_i in (plot, lines, scatter, scatterlines, linesegments, stairs, stem, waterfall)
                x = parent(lookup(to_value(dd_i), 1))
                y = collect(parent(to_value(dd_i)))
                fig, ax, plt = plot_i(obs(dd_i))
                @test all(first.(plt[1][]) .== ustrip.(x)) 
                @test all(last.(plt[1][]) .== ustrip.(y))
                @test ax.xlabel[] == "Time"
                @test ax.ylabel[] == "test"
                @test plt.label[] == "test"
            end
        end
    end

    dd_char_vec = DimArray((1:5).^2, X(Char.(70:74)), name=:test)
    dd_symbol_vec = DimArray((1:5).^2, X(Symbol.(Char.(70:74))), name=:test)
    for dd_i in (dd_char_vec, dd_symbol_vec)
        for obs in (Observable, identity)
            for plot_i in (plot, lines, scatter, scatterlines, linesegments, stairs, stem, waterfall)
                x = parent(lookup(to_value(dd_i), 1))
                y = collect(parent(to_value(dd_i)))
                fig, ax, plt = plot_i(dd_i)
                @test ax.xlabel[] == "X"
                @test ax.ylabel[] == "test"
                @test plt.label[] == "test"
                @test all(last.(plt[1][]) .== Int.(y))
                if dd_i isa DimArray{<:AbstractChar}
                    @test all(first.(plt[1][]) .== Int.(x)) 
                else
                    @test all(first.(plt[1][]) .== sum.(Int, string.(x)))
                end
            end
        end
    end

    dd_i = DimArray([missing, 2, 3, 4, 5], Ti('A':'E'), name= "test")
    for plot_i in (plot, lines, scatter, scatterlines, linesegments, stairs, stem, waterfall)
        for obs in (Observable, identity)
            x = parent(lookup(to_value(dd_i), 1))
            y = collect(parent(to_value(dd_i)))
            fig, ax, plt = plot_i(obs(dd_i))
            @test ax.xlabel[] == "Time"
            @test ax.ylabel[] == "test"
            @test plt.label[] == "test"
            @test all(first.(plt[1][]) .== Int.(x))
            @test all(last.(plt[1][]) .=== replace(y, missing => NaN)) 
        end
    end


    fig, ax, plt = lines(dd_vec_mis; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), figure = (;size = (1000, 1000)), linewidth = 5)
    @test plt.linewidth[] == 5
    @test ax.xlabel[] == "new_x"
    @test ax.ylabel[] == "new_y"
    @test ax.title[] == "new_title"
    @test fig.content[2] isa Makie.Legend
    @test fig.content[1] isa Makie.Axis

    fig, ax, plt = lines(dd_vec_mis, axislegend = (;unique = false))
    @test fig.content[2] isa Makie.Legend

    fig, ax, plt = lines(dd_vec_mis, axis = (;type = LScene), axislegend = false)
    @test fig.content[1] isa Makie.LScene
    @test length(fig.content) == 1

    fig, ax, plt = plot(dd_vec_mis)
    @test plt isa Makie.Scatter
    fig = Figure()
    @test plot(fig[1,1], dd_vec_mis) isa Makie.AxisPlot
    @test_throws ErrorException plot(fig[1,1], dd_vec_mis)

    fig = Figure()
    @test plot(fig[1,1][1,1], dd_vec_mis) isa Makie.AxisPlot
    @test_throws ErrorException plot(fig[1,1][1,1], dd_vec_mis)

    fig = Figure()
    ax = Axis(fig[1,1])
    @test plot!(ax, dd_vec) isa Makie.Scatter

    dd_cat = rand(X('a':'b'), Y(1:6), name = :test)
    
    for obs in (Observable, identity)
        for plot_i in (rainclouds, violin, boxplot)
            x = parent(lookup(to_value(dd_cat), Y))
            y = collect(parent(to_value(dd_cat)))
            fig, ax, plt = plot_i(obs(dd_cat))
            @test all(plt[1][] .== repeat(97:98, outer = 6)) 
            @test all(plt[2][] .== vec(y'))
            @test ax.xlabel[] == "X"
            @test ax.ylabel[] == "test"
            @test plt.label[] == "test"

            fig, ax, plt = plot_i(obs(dd_cat), categoricaldim = Y)
            @test all(plt[1][] .== repeat(1:6, outer = 2))
        end
    end


    dd_cat = DimArray((1:6).^2, X(cat(fill('A', 3), fill('B', 3), dims = 1)), name = :test)
    for plot_i in (rainclouds, violin, boxplot)
        fig, ax, plt = plot_i(dd_cat)
        @test all(plt[1][] .== Int.(lookup(dd_cat, X)))
        @test all(plt[2][] .== Int.(parent(dd_cat)))
        @test_throws ArgumentError plot_i(dd_cat, categoricaldim = Y) 
    end


    for dd_i in (dd_vec_mis, dd_vec_uni) # These plot do not work with missing and unitful due to Makie limitations
        for plt_i in ( rainclouds, violin, boxplot)
            @test plt_i(dd_i) broken = true
        end
    end

    # Test if update plots with Observable works 
    x = Observable(X(collect(1:5)))
    y = Observable(11:15)
    label = Observable("test")
    dd_vec = lift((x, y, label) -> DimArray(y, (x,); name = label), x, y, label)
    fig, ax, plt = lines(dd_vec)
    @test all(first.(plt[1][]) .== x[])
    @test all(last.(plt[1][]) .== y[])
    @test plt.label[] == label[]

    label[] = "new_test"
    x[] = X(collect(11:15))  
    y[] = 21:25

    @test all(first.(plt[1][]) .== 11:15)
    @test all(last.(plt[1][]) .== 21:25)
    @test plt.label[] == "new_test" 
end

@testset "Series" begin
    dd_mat_cat = DimArray(rand(2, 3), (Y('a':'b'), X(1:3)); name = :test)
    dd_mat_sym = DimArray(rand(2, 3), (Y(Symbol.('a':'b')), X(1:3)); name = :test)
    dd_mat_num = DimArray(rand(2, 3), (Y(1:2), X(1:3)); name = :test)
    dd_mat_uni = DimArray(ones(2, 3) .* m, (Y((1:2) .* s), X((1:3) .*  F)); name = :test)

    fig = Figure()
    @test_throws MethodError series(fig, dd_mat_cat) # as lines(fig, 1:10)
    ax, plt = series(fig[1,1], dd_mat_cat)
    @test_throws ErrorException series(fig[1,1], dd_mat_cat)
    series!(ax, dd_mat_cat)
    
    for dd_i in (dd_mat_cat, dd_mat_num, dd_mat_sym, dd_mat_uni) 
        fig, ax, plt = series(dd_i)
        @test ax.ylabel[] == "test"
        @test ax.xlabel[] == "X"
        @test all(first.(plt[1][][1]) .== ustrip.(lookup(dd_i, X)))
        @test all(first.(plt[1][][2]) .== ustrip.(lookup(dd_i, X)))
        @test all(last.(plt[1][][1]) .== ustrip.(dd_i[1,:]))
        @test all(last.(plt[1][][2]) .== ustrip.(dd_i[2,:]))
    end

    # Check that colors are resampled if categorical size is bigger than the default colormap size
    dd_big = rand(X(10), Y(10))
    fig, ax, plt = series(rand(X(10), Y(5)))
    @test plt.color[] == Makie.resample_cmap(Makie.to_colormap(:lighttest), 7)
    fig, ax, plt = series(dd_big)
    @test plt.color[] == Makie.resample_cmap(Makie.to_colormap(:lighttest), 10)
    fig, ax, plt = series(Observable(dd_big))
    @test plt.color[] == Makie.resample_cmap(Makie.to_colormap(:lighttest), 10)
    fig, ax, plt = series(Observable(dd_big), color = Makie.wong_colors())
    @test plt.color[] == Makie.resample_cmap(Makie.wong_colors(), 10)
    fig, ax, plt = series(Observable(dd_big), color = :inferno)
    @test plt.color[] == Makie.resample_cmap(Makie.to_colormap(:inferno), 10)

    fig, ax, plt = series(dd_mat_cat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), figure = (;size = (1000, 1000)), linewidth = 5)
    @test plt.linewidth[] == 5
    @test ax.xlabel[] == "new_x"
    @test ax.ylabel[] == "new_y"
    @test ax.title[] == "new_title"
    @test fig.content[2] isa Makie.Legend
    @test fig.content[1] isa Makie.Axis

    fig, ax, plt = series(dd_mat_cat, axis = (;type = LScene), axislegend = false)
    @test fig.content[1] isa Makie.LScene
    @test length(fig.content) == 1

    fig, ax, plt = series(dd_mat_cat, axis = (;type = LScene), axislegend = (; unique = false))
    
    x = Observable(X(collect(1:5)))
    y = Observable(Y('A':'B'))
    z = Observable(rand(5, 2))
    dd_mat = lift((x,y,z) -> DimArray(z, (x, y); name = "test"), x, y, z)

    fig, ax, plt = series(dd_mat)
    @test all(first.(plt[1][][1]) .== lookup(dd_mat[], X))
    @test all(first.(plt[1][][2]) .== lookup(dd_mat[], X))
    @test all(last.(plt[1][][1]) .≈  dd_mat[][:,1])
    @test all(last.(plt[1][][2]) .== dd_mat[][:,2])

    x[] = X(collect(11:15))
    y[] = Y('C':'D')
    z[] = rand(5, 2)
    @test all(first.(plt[1][][1]) .== 11:15)    
    @test all(first.(plt[1][][2]) .== 11:15)
    @test all(last.(plt[1][][1]) .==  dd_mat[][:,1])
    @test all(last.(plt[1][][2]) .== dd_mat[][:,2])

    dd_vec = DimArray(rand(5, 2), (X(1:5), Y('A':'B')), name=:test)
    fig, ax, plt = series(dd_vec)
    @test length(plt[1][]) == 2 

    fig, ax, plt = series(dd_vec, labeldim = X)
    @test length(plt[1][]) == 5

    dd_vec = DimArray(rand(5, 2), (Y(1:5), X('A':'B')), name=:test)
    fig, ax, plt = series(dd_vec)
    @test length(plt[1][]) == 2
end

@testset "2D plots" begin
    x = 1:5
    y = 10:20
    dd_mat = DimArray( x.^1/2 .+ 0y'.^1/3, (X(x), Y(y)), name=:test)
    dd_mat_perm = DimArray( x.^1/2 .+ 0y'.^1/3, (Y(x), X(y)), name=:test)
    dd_mat_uni = DimArray( (x.^1/2 .+ 0y'.^1/3) .* F, (Y(x .* m), X(y .* s)), name=:test)
    dd_mat_char = DimArray( x.^1/2 .+ 0y'.^1/3, (Y('a':'e'), X(y)), name=:test)
    dd_mat_sym = DimArray( x.^1/2 .+ 0y'.^1/3, (Y(Symbol.('a':'e')), X(y)), name=:test)

    fig = Figure()
    @test_throws MethodError contour(fig, dd_mat) # as lines(fig, 1:10)
    ax, plt = contour(fig[1,1], dd_mat)
    contourf!(ax, dd_mat)
    @test_throws ErrorException contour(fig[1,1], dd_mat)

    fig, ax, plt = contour(dd_mat)
    for dd_i in (dd_mat, dd_mat_perm)
        for obs_i in (Observable, identity)
            for plt_i in (contour3d, surface, contour, contourf)
                fig, ax, plt = contour(obs_i(dd_i))
                @test plt[1][] == lookup(to_value(dd_i), X)
                @test plt[2][] == lookup(to_value(dd_i), Y)
                @test plt[3][] == permutedims(to_value(dd_i), (X, Y))
                @test ax.xlabel[] == "X"
                @test ax.ylabel[] == "Y"
            end
        end
    end
    
    for dd_i in (dd_mat, dd_mat_perm)
        for obs_i in (Observable, identity)
            for plt_i in (image, spy)
                fig, ax, plt = plt_i(dd_i)
                @test plt[1][] == extrema(lookup(to_value(dd_i), X))
                @test plt[2][] == extrema(lookup(to_value(dd_i), Y))
                @test plt[3][] == permutedims(to_value(dd_i), (X, Y))
                @test ax.xlabel[] == "X"
                @test ax.ylabel[] == "Y"
            end
        end
    end

    for dd_i in (dd_mat, dd_mat_perm)
        for obs_i in (Observable, identity)
            fig, ax, plt = heatmap(dd_i)
            @test plt[1][][2:end] == lookup(to_value(dd_i), X) .+ .5
            @test plt[2][][2:end] == lookup(to_value(dd_i), Y) .+ .5
            @test plt[3][] == permutedims(to_value(dd_i), (X, Y))
            @test ax.xlabel[] == "X"
            @test ax.ylabel[] == "Y"
        end
    end

    dd_mat_char = DimArray( x.^1/2 .+ 0y'.^1/3, (Y('a':'e'), X(y)), name=:test)
    fig, ax, plt = contourf(dd_mat_char)
    @test plt[1][] == lookup(dd_mat_char, X)
    @test plt[2][] == Int.(lookup(dd_mat_char, Y))
    @test ax.yticks[][2] == string.(lookup(dd_mat_char, Y))

    dd_mat_sym = DimArray( x.^1/2 .+ 0y'.^1/3, (X(Symbol.('a':'e')), Y(y)), name=:test)
    fig, ax, plt = contourf(dd_mat_sym)
    @test plt[1][] == Int.(first.(string.(lookup(dd_mat_sym, X))))
    @test plt[2][] == Int.(lookup(dd_mat_sym, Y))
    @test ax.xticks[][2] == string.(lookup(dd_mat_sym, X))

    dd_mat_uni = DimArray( (x.^1/2 .+ 0y'.^1/3) .* F, (Y(x .* m), X(y .* s)), name=:test)
    @test heatmap(dd_mat_uni)[3] isa Heatmap broken = true # Makie limitation
    @test contourf(dd_mat_uni)[3] isa Contourf broken = true # Makie limitation
    @test image(dd_mat_uni)[3] isa Contourf broken = true # Makie limitation

    # test if arguments are overwritten
    fig, ax, plt = contourf(dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), figure = (;size = (1000, 1000)), colormap = :inferno)
    @test plt.colormap[] == :inferno
    @test ax.xlabel[] == "new_x"
    @test ax.ylabel[] == "new_y"
    @test ax.title[] == "new_title"
    @test fig.content[2] isa Makie.Colorbar    
    @test fig.content[2].label[] == "test"

    fig, ax, plt = contourf(dd_mat; xdim = Y, ydim = X)
    @test plt[1][] == lookup(dd_mat, Y)
    @test plt[2][] == lookup(dd_mat, X)
    @test plt[3][] == permutedims(dd_mat, (Y, X))
    @test ax.xlabel[] == "Y"
    @test ax.ylabel[] == "X"

    fig, ax, plt = heatmap(dd_mat; colorbar = false)
    @test length(fig.content) == 1

    fig, ax, plt = heatmap(dd_mat; axis = (;type = LScene))
    @test ax isa Makie.LScene
    for plt_i in (heatmap, contourf, spy, surface)
        fig, ax, plt = plt_i(dd_mat)
        @test fig.content[2] isa Colorbar
    end

    fig, ax, plt = heatmap(dd_mat; axis = (;type = PolarAxis))
    @test ax isa Makie.PolarAxis

    @test_throws Makie.InvalidAttributeError surface(dd_mat; axis = (;xlabel = "new")) # Throws an error as normal makie would

    dd_rgb = rand(RGB, X(1:10), Y(1:5))
    fig, ax, plt = heatmap(dd_rgb)
    @test plt isa Heatmap
    fig, ax, plt = image(dd_rgb)
    @test plt isa Image
    
    x = Observable(1:5)
    y = Observable(1:6)
    z = lift((x,y) -> x.^2 .+ y', x, y)
    name_string = Observable("test")
    dd_obs = lift((x,y,z,name_string) -> DimArray(z, (X(x), Y(y)), name = name_string), x, y, z, name_string)

    fig, ax, plt = contourf(dd_obs)
    @test all(plt[1][] .== x[])
    @test all(plt[2][] .== y[])
    @test all(plt[3][] .== permutedims(dd_obs[], (X, Y)))
    @test fig.content[2].label[] == "test"

    x[] = 6:10
    y[] = 6:11
    @test all(plt[1][] .== 6:10)
    @test all(plt[2][] .== 6:11)
    @test all(plt[3][] .== permutedims(dd_obs[], (X, Y)))
    
    name_string[] = "new_test"
    @test fig.content[2].label[] == "new_test"
end

@testset "3D plots" begin
    dd_3d = DimArray(rand(5, 5, 5), (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d_mis = DimArray(reshape(vcat([missing], rand(7)), 2, 2, 2), (X(1:2), Y(1:2), Z(1:2)), name=:test)
    dd_3d_uni = DimArray(rand(5, 5, 5) .* m, (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d_rgb = DimArray(rand(RGB, 5, 5, 5), (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d = DimArray(rand(5, 5, 5), (Z(1:5), X(1:5), Y(1:5)), name=:test)
    
    fig = Figure()
    @test_throws MethodError volume(fig, dd_3d) # as lines(fig, 1:10)
    ax, plt = volume(fig[1,1], dd_3d)
    @test_throws ErrorException volume(fig[1,1], dd_3d)
    @test volume!(ax, dd_3d) isa Makie.Volume

    fig = Figure()
    lines(fig[1,2], rand(10))
    volume(fig[1,1], dd_3d)
    fig
    
    for dd_i in (dd_3d, dd_3d_mis)
        for plt_i in (volume, plot)
            for obs_i in (identity, Observable)
                fig, ax, plt = plt_i(obs_i(dd_i))
                @test plt[1][] == extrema(lookup(to_value(dd_i), X)) 
                @test plt[2][] == extrema(lookup(to_value(dd_i), Y))
                @test plt[3][] == extrema(lookup(to_value(dd_i), Z)) 
                @test all(plt[4][] .=== Float32.(replace(parent(permutedims(to_value(dd_i), (X, Y, Z))), missing => NaN32)))
                @test ax isa Makie.LScene
                @test fig.content[2] isa Makie.Colorbar
                @test fig.content[2].label[] == "test"
            end
        end
    end

    for obs_i in (identity, Observable)
        fig, ax, plt = volumeslices(obs_i(dd_3d))
        @test plt[1][] == lookup(to_value(dd_3d), X)
        @test plt[2][] == lookup(to_value(dd_3d), Y)
        @test plt[3][] == lookup(to_value(dd_3d), Z)
        @test plt[4][] == parent(permutedims(to_value(dd_3d), (X, Y, Z)))
        @test ax isa Makie.LScene
        @test fig.content[2] isa Makie.Colorbar
        @test fig.content[2].label[] == "test"
    end

    dd_3d_char = DimArray(rand(5, 5, 5), (X('A':'E'), Y(1:5), Z(1:5)), name=:test)
    @test volume(dd_3d_char) isa Makie.FigureAxisPlot
    @test volumeslices(dd_3d_char) isa Makie.FigureAxisPlot

    # Due to limitations on Makie
    @test volumeslices(dd_3d_mis) broken = true 
    @test volumeslices(dd_3d_uni) broken = true
    @test volumeslices(dd_3d_rgb) broken = true
    @test volume(dd_3d_uni) broken = true
    @test volume(dd_3d_rgb) broken = true

    fig, ax, plt = volume(dd_3d; xdim = Y, ydim = Z, zdim = X)
    @test plt[1][] == extrema(lookup(to_value(dd_3d), Y))
    @test plt[2][] == extrema(lookup(to_value(dd_3d), Z))
    @test plt[3][] == extrema(lookup(to_value(dd_3d), X))
    @test_throws ArgumentError volume(dd_3d; xdim = Y, ydim = Z, zdim = Y)

    x = Observable(1:5)
    y = Observable(11:15)
    z = Observable(21:25)
    c = Observable(rand(Int, 5, 5, 5))
    dd_3d_obs = lift((c, x, y, z) -> DimArray(c, (Y(y), Z(z), X(x)), name = "test"), c, x, y, z)

    fig, ax, plt = volumeslices(dd_3d_obs)
    @test plt[1][] == lookup(dd_3d_obs[], X)
    @test plt[2][] == lookup(dd_3d_obs[], Y)
    @test plt[3][] == lookup(dd_3d_obs[], Z)
    @test plt[4][] == parent(permutedims(dd_3d_obs[], (X, Y, Z)))

    x[] = 6:10
    y[] = 16:20
    z[] = 26:30
    c[] = rand(Int, 5, 5, 5)
    @test plt[1][] == lookup(dd_3d_obs[], X)
    @test plt[2][] == lookup(dd_3d_obs[], Y)
    @test plt[3][] == lookup(dd_3d_obs[], Z)
    @test plt[4][] == parent(permutedims(dd_3d_obs[], (X, Y, Z)))
end

# end

@testset "AlgebraOfGraphics" begin

    # 1d
    A1 = rand(X(1:5); name=:test)
    A1c = rand(X('a':'e'); name=:test)

    @testset "1d, symbol indexing" begin
        @test_nowarn data(A1) * mapping(:X, :test) * visual(CairoMakie.Lines) |> draw
        @test_nowarn data(A1c) * mapping(:X, :test) * visual(CairoMakie.Lines) |> draw
    end

    @testset "1d, dim indexing" begin
        @test_nowarn data(A1) * mapping(X, :test) * visual(CairoMakie.Lines) |> draw
        @test_nowarn data(A1c) * mapping(X, :test) * visual(CairoMakie.Lines) |> draw
    end

    A3 = DimArray(rand(21, 5, 4), (X, Y, Dim{:p}); name = :RandomData)
    
    @testset "3d faceting" begin
        @test_nowarn data(A3) * visual(CairoMakie.Heatmap) * mapping(X, :RandomData, Dim{:p}, layout = Y => nonnumeric) |> draw
        fg = data(A3) * visual(CairoMakie.Heatmap) * mapping(X, :RandomData, Dim{:p}, layout = Y => nonnumeric) |> draw
        # Test that the number of axes is equal to the size of A3 in the y dimension.
        @test sum(x -> x isa AlgebraOfGraphics.Makie.Axis, AlgebraOfGraphics.Makie.contents(fg.figure.layout)) == size(A3, Y)
    end

    @testset "DimPoints" begin
        DimPoints(rand(X(10), Y(1.0:0.1:2.0))) |> Makie.scatter
        DimPoints(rand(X(10), Y(1.0:0.1:2.0))) |> Makie.plot
        DimPoints(rand(X(10), Y(1.0:0.1:2.0), Z(10:10:40))) |> Makie.scatter
        DimPoints(rand(X(10), Y(1.0:0.1:2.0), Z(10:10:40))) |> Makie.plot
    end
end


@testset "Makie" begin

    using CairoMakie: CairoMakie as M
    using ColorTypes

    # 1d
    A1 = rand(X('a':'e'); name=:test)
    A1m = rand([missing, (1:3.)...], X('a':'e'); name=:test)
    A1u = rand([missing, (1:3.)...], X(1s:1s:3s); name=:test)
    A1ui = rand([missing, (1:3.)...], X(1s:1s:3s; sampling=Intervals(Start())); name=:test)
    A1num = rand(X(-10:10))
    A1m .= A1
    A1m[3] = missing
    fig, ax, _ = M.plot(A1)
    M.plot!(ax, A1)
    fig, ax, _ = M.plot(A1m)
    fig, ax, _ = M.plot(parent(A1m))
    M.plot!(ax, A1m)
    fig, ax, _ = M.plot(A1u)
    #M.plot!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.plot(A1ui)
    #M.plot!(ax, A1ui) # Does not work due to Makie limitation related with missing

    fig, ax, _ = M.plot(A1num)
    M.reset_limits!(ax)
    org = first(ax.finallimits.val.origin)
    wid = first(M.widths(ax.finallimits.val))
    # This tests for #714
    @test org <= -10
    @test org + wid >= 10
    fig, ax, _ = M.scatter(A1)
    M.scatter!(ax, A1)
    fig, ax, _ = M.scatter(A1m)
    M.scatter!(ax, A1m)
    fig, ax, _ = M.lines(A1)
    M.lines!(ax, A1)
    fig, ax, _ = M.lines(A1u)
    # M.lines!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.lines(A1m)
    M.lines!(ax, A1m)
    fig, ax, _ = M.scatterlines(A1)
    M.scatterlines!(ax, A1)
    fig, ax, _ = M.scatterlines(A1u)
    # M.scatterlines!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.scatterlines(A1m)
    M.scatterlines!(ax, A1m)
    fig, ax, _ = M.stairs(A1)
    M.stairs!(ax, A1)
    fig, ax, _ = M.stairs(A1u)
    # M.stairs!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.stairs(A1m)
    M.stairs!(ax, A1m)
    fig, ax, _ = M.stem(A1)
    M.stem!(ax, A1)
    fig, ax, _ = M.stem(A1u)
    # M.stem!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.stem(A1m)
    M.stem!(ax, A1m)
    fig, ax, _ = M.barplot(A1)
    M.barplot!(ax, A1)
    fig, ax, _ = M.barplot(A1u)
    # M.barplot!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.barplot(A1m)
    M.barplot!(ax, A1m)
    fig, ax, _ = M.waterfall(A1)
    M.waterfall!(ax, A1)
    fig, ax, _ = M.waterfall(A1u)
    # M.waterfall!(ax, A1u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.waterfall(A1m)
    M.waterfall!(ax, A1m)

    # 2d
    A2 = rand(X(10:10:100), Y(['a', 'b', 'c']))
    A2r = rand(Y(10:10:100), X(['a', 'b', 'c']))
    A2m = rand([missing, (1:5)...], Y(10:10:100), X(['a', 'b', 'c']))
    A2u = rand(Y(10km:10km:100km), X(['a', 'b', 'c']))
    A2ui = rand(Y(10km:10km:100km; sampling=Intervals(Start())), X(['a', 'b', 'c']))
    A2m[3] = missing
    A2rgb = rand(RGB, X(10:10:100), Y(['a', 'b', 'c']))

    fig, ax, _ = M.plot(A2)
    M.plot!(ax, A2)
    fig, ax, _ = M.plot(A2m)
    M.plot!(ax, A2m)
    # fig, ax, _ = M.plot(A2u) # Does not work due to Makie limitation
    # e.g. heatmap((1:10)m, (1:10)m, rand(10,10))

    # M.plot!(ax, A2u)
    # fig, ax, _ = M.plot(A2ui)
    # M.plot!(ax, A2ui)
    fig, ax, _ = M.plot(A2rgb)
    M.plot!(ax, A2rgb)
    fig, ax, _ = M.heatmap(A2)
    M.heatmap!(ax, A2)
    fig, ax, _ = M.heatmap(A2m)
    M.heatmap!(ax, A2m)
    fig, ax, _ = M.heatmap(A2rgb)
    M.heatmap!(ax, A2rgb)
    fig, ax, _ = M.image(A2)
    M.image!(ax, A2)
    fig, ax, _ = M.image(A2m)
    M.image!(ax, A2m)
    fig, ax, _ = M.image(A2rgb)
    M.image!(ax, A2rgb)
    fig, ax, _ = M.violin(A2r)
    M.violin!(ax, A2r)
    @test_throws ArgumentError M.violin(A2m)
    @test_throws ArgumentError M.violin!(ax, A2m)

    fig, ax, _ = M.rainclouds(A2)
    M.rainclouds!(ax, A2)
    fig, ax, _ = M.rainclouds(A2u)
    M.rainclouds!(ax, A2u)
    @test_throws ErrorException M.rainclouds(A2m) # MethodError ? missing values in data not supported

    fig, ax, _ = M.surface(A2)
    M.surface!(ax, A2)
    # fig, ax, _ = M.surface(A2ui) # Does not work due to Makie limitation
    # M.surface!(ax, A2ui)

    # Broken with missing
    # fig, ax, _ = M.surface(A2m)
    # M.surface!(ax, A2m)
    # Series also puts Categories in the legend no matter where they are
    # TODO: method series! is incomplete, we need to include the colors logic, as in series. There should not be any issue if the correct amount of colours is provided.
    fig, ax, _ = M.series(A2)
    M.series!(ax, A2)
    fig, ax, _ = M.series(A2u)
    # M.series!(ax, A2u) # Does not work due to Makie limitation related with missing
    fig, ax, _ = M.series(A2ui)
    # M.series!(ax, A2u)
    fig, ax, _ = M.series(A2r)
    # M.series!(ax, A2r)
    fig, ax, _ = M.series(A2r; labeldim=Y)
    # M.series!(ax, A2r; labeldim=Y)
    fig, ax, _ = M.series(A2m)
    # M.series!(ax, A2m)
    @test_throws ArgumentError M.plot(A2; ydim=:c)
    # @test_throws ArgumentError M.plot!(ax, A2; y=:c)

    # x/y can be specified
    A2ab = DimArray(rand(6, 10), (:a, :b); name=:stuff)
    fig, ax, _ = M.plot(A2ab)
    M.plot!(ax, A2ab)
    fig, ax, _ = M.contourf(A2ab; xdim=:a)
    M.contourf!(ax, A2ab, xdim=:a)
    fig, ax, _ = M.heatmap(A2ab; ydim=:b)
    M.heatmap!(ax, A2ab; ydim=:b)
    fig, ax, _ = M.series(A2ab)
    M.series!(ax, A2ab)
    fig, ax, _ = M.boxplot(A2ab)
    M.boxplot!(ax, A2ab)
    fig, ax, _ = M.violin(A2ab)
    M.violin!(ax, A2ab)
    # fig, ax, _ = M.rainclouds(A2ab) # Does not work due to Makie limitation
    # M.rainclouds!(ax, A2ab) # Does not work due to Makie limitation
    fig, ax, _ = M.surface(A2ab)
    M.surface!(ax, A2ab)
    fig, ax, _ = M.series(A2ab)
    M.series!(ax, A2ab)
    fig, ax, _ = M.series(A2ab; labeldim=:a)
    M.series!(ax, A2ab; labeldim=:a)

    fig, ax, _ = M.series(A2ab; labeldim=:b)
    # M.series!(ax, A2ab; labeldim=:b)

    # 3d, all these work with GLMakie
    A3 = rand(X(7), Z(10), Y(5))
    A3u = rand(X((1:7)m), Z((1.0:1:10.0)m), Y((1:5)g))
    A3m = rand([missing, (1:7)...], X(7), Z(10), Y(5))
    A3m[3] = missing
    A3rgb = rand(RGB, X(7), Z(10), Y(5))
    fig, ax, _ = M.volume(A3)
    M.volume!(ax, A3)
    fig, ax, _ = M.volume(A3m)
    M.volume!(ax, A3m)

    # Units are broken in Makie ?
    # fig, ax, _ = M.volume(A3u)
    # M.volume!(ax, A3u)

    fig, ax, _ = M.volumeslices(A3)
    M.volumeslices!(ax, A3)
    # Need to manually specify colorrange
    fig, ax, _ = M.volumeslices(A3m; colorrange=(1, 7))
    M.volumeslices!(ax, A3m; colorrange=(1, 7))

    # Unitful volumeslices broken in Makie ?
    # fig, ax, _ = M.volumeslices(A3u)
    # M.volumeslices!(ax, A3u)

    # RGB volumeslices broken in Makie ?
    # fig, ax, _ = M.volumeslices(A3rgb)
    # M.volumeslices!(ax, A3rgb)
    # fig, ax, _ = M.volumeslices(A3rgb)
    # M.volumeslices!(ax, A3rgb)
    # x/y/z can be specified
    A3abc = DimArray(rand(10, 10, 7), (:a, :b, :c); name=:stuff)
    fig, ax, _ = M.volume(A3abc; xdim=:c)
    fig, ax, _ = M.volumeslices(A3abc; xdim=:c)
    fig, ax, _ = M.volumeslices(A3abc; zdim=:a)
    M.volumeslices!(ax, A3abc; zdim=:a)

    "LScene support"
    f, a, p = M.heatmap(A2ab; axis=(; type=M.LScene, show_axis=false))
    @test a isa M.LScene
    @test isnothing(a.scene[M.OldAxis])

    "Colorbar support"
    fig, ax, _ = M.plot(A2ab; colorbar=(; width=50))
    colorbars = filter(x -> x isa M.Colorbar, fig.content)
    @test length(colorbars) == 1
    @test colorbars[1].label[] == "stuff"
    @test colorbars[1].width[] == 50

    A2ab_unnamed = DimArray(A2ab.data, DD.dims(A2ab))
    fig, ax, _ = M.plot(A2ab_unnamed)
    colorbars = filter(x -> x isa M.Colorbar, fig.content)
    @test length(colorbars) == 1
    @test colorbars[1].label[] == ""
end

end

