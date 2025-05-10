using DimensionalData, Test, Dates
using AlgebraOfGraphics
using CairoMakie
using ColorTypes
using Unitful
import Distributions
import DimensionalData as DD
# using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
#     Sampled, Categorical, NoLookup, Transformed,
#     Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

@testset "1D plots" begin 
    dd_vec = DimArray((1:5).^2, Ti(1:5), name=:test)
    dd_range = DimArray(1:5, Ti(1:5), name=:test) # test for #949
    dd_vec_mis = DimArray([missing, 2, 3, 4, 5], Ti('A':'E'), name= "test")
    dd_vec_uni = DimArray(.√(1:5) .* u"m", Ti((1:5) .* u"F"), name= "test")

    for dd_i in (dd_vec, dd_vec_uni, dd_range)
        for obs in (Observable, identity)
            for plot_i in (plot, lines, scatter, scatterlines, linesegments, stairs, stem, waterfall)
                x = parent(lookup(to_value(dd_i), 1))
                y = collect(parent(to_value(dd_i)))
                fig, ax, plt = plot_i(obs(dd_i))
                @test all(first.(plt[1][]) .== ustrip(x)) 
                @test all(last.(plt[1][]) .== ustrip(y))
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
    
    for obs in (Observable, identity)
        for plot_i in (rainclouds, violin, boxplot)
            x = parent(lookup(to_value(dd_vec), 1))
            y = collect(parent(to_value(dd_vec)))
            fig, ax, plt = plot_i(obs(dd_vec))
            @test all(plt[1][] .== ustrip(x)) 
            @test all(plt[2][] .== ustrip(y))
            @test ax.xlabel[] == "Time"
            @test ax.ylabel[] == "test"
            @test plt.label[] == "test"
        end
    end

    dd_cat = DimArray((1:6).^2, X(cat(fill('A', 3), fill('B', 3), dims = 1)), name = :test)
    for plot_i in (rainclouds, violin, boxplot)
        fig, ax, plt = plot_i(dd_cat)
        @test all(plt[1][] .== Int.(lookup(dd_cat, X)))
        @test all(plt[2][] .== Int.(parent(dd_cat)))
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
    dd_vec = @lift DimArray($y, ($x,); name = $label)
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
    dd_mat_uni = DimArray(rand(2, 3) .* u"m", (Y((1:2) .* u"s"), X((1:3) .* u"F")); name = :test)
    
    for dd_i in (dd_mat_cat, dd_mat_num, dd_mat_sym) 
        fig, ax, plt = series(dd_i)
        @test plt.label[] == "test"
        @test ax.ylabel[] == "test"
        @test ax.xlabel[] == "X"
        @test all(first.(plt[1][][1]) .== lookup(dd_i, X))
        @test all(first.(plt[1][][2]) .== lookup(dd_i, X))
        @test all(last.(plt[1][][1]) .== dd_i[1,:])
        @test all(last.(plt[1][][2]) .== dd_i[2,:])
    end

    @test series(dd_mat_uni) broken = true # Does not work because of issue #4946 of Makie

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
    @test plt.color[] == Makie.to_colormap(:inferno)

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
    label = Observable("test")
    dd_mat = @lift DimArray($z, ($x, $y); name = $label)

    fig, ax, plt = series(dd_mat)
    @test all(first.(plt[1][][1]) .== lookup(dd_mat[], X))
    @test all(first.(plt[1][][2]) .== lookup(dd_mat[], X))
    @test all(last.(plt[1][][1]) .≈  dd_mat[][:,1])
    @test all(last.(plt[1][][2]) .== dd_mat[][:,2])
    @test plt.label[] == label[]

    label[] = "new_test"
    x[] = X(collect(11:15))
    y[] = Y('C':'D')
    z[] = rand(5, 2)
    @test all(first.(plt[1][][1]) .== 11:15)    
    @test all(first.(plt[1][][2]) .== 11:15)
    @test all(last.(plt[1][][1]) .==  dd_mat[][:,1])
    @test all(last.(plt[1][][2]) .== dd_mat[][:,2])
    @test plt.label[] == "new_test"

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
    dd_mat_uni = DimArray( (x.^1/2 .+ 0y'.^1/3) .* u"Ω", (Y(x .* u"m"), X(y .* u"s")), name=:test)
    dd_mat_char = DimArray( x.^1/2 .+ 0y'.^1/3, (Y('a':'e'), X(y)), name=:test)
    dd_mat_sym = DimArray( x.^1/2 .+ 0y'.^1/3, (Y(Symbol.('a':'e')), X(y)), name=:test)

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
                @test plt[1][] == extrema(lookup(to_value(dd_i), X)) .+ (-.5, .5)
                @test plt[2][] == extrema(lookup(to_value(dd_i), Y)) .+ (-.5, .5)
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

    dd_mat_uni = DimArray( (x.^1/2 .+ 0y'.^1/3) .* u"Ω", (Y(x .* u"m"), X(y .* u"s")), name=:test)
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

    fig, ax, plt = contourf(dd_mat; x = Y, y = X)
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

    @test_throws Makie.MakieCore.InvalidAttributeError surface(dd_mat; axis = (;xlabel = "new")) # Throws an error as normal makie would

    dd_rgb = rand(RGB, X(1:10), Y(1:5))
    fig, ax, plt = heatmap(dd_rgb)
    @test plt isa Heatmap
    fig, ax, plt = image(dd_rgb)
    @test plt isa Image
    
    x = Observable(1:5)
    y = Observable(1:6)
    z = @lift $x.^2 .+ $y'
    name_string = Observable("test")
    dd_obs = @lift DimArray($z, (X($x), Y($y)), name = $name_string)

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
    dd_3d_uni = DimArray(rand(5, 5, 5) .* u"m", (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d_rgb = DimArray(rand(RGB, 5, 5, 5), (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d = DimArray(rand(5, 5, 5), (Z(1:5), X(1:5), Y(1:5)), name=:test)
    
    for dd_i in (dd_3d, dd_3d_mis)
        for plt_i in (volume, plot)
            for obs_i in (identity, Observable)
                fig, ax, plt = plt_i(obs_i(dd_i))
                @test plt[1][] == extrema(lookup(to_value(dd_i), X)) .+ (-0.5, +.5)
                @test plt[2][] == extrema(lookup(to_value(dd_i), Y)) .+ (-0.5, +.5)
                @test plt[3][] == extrema(lookup(to_value(dd_i), Z)) .+ (-0.5, +.5)
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

    fig, ax, plt = volume(dd_3d; x = Y, y = Z, z = X)
    @test plt[1][] == extrema(lookup(to_value(dd_3d), Y)) .+ (-0.5, +.5)
    @test plt[2][] == extrema(lookup(to_value(dd_3d), Z)) .+ (-0.5, +.5)
    @test plt[3][] == extrema(lookup(to_value(dd_3d), X)) .+ (-0.5, +.5)
    @test_throws ArgumentError volume(dd_3d; x = Y, y = Z, z = Y)

    x = Observable(1:5)
    y = Observable(11:15)
    z = Observable(21:25)
    c = Observable(rand(Int, 5, 5, 5))
    dd_3d_obs = @lift DimArray($c, (Y($y), Z($z), X($x)), name = "test")

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
