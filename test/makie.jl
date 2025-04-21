using DimensionalData, Test, Dates
using AlgebraOfGraphics
using CairoMakie
import CairoMakie as M
using ColorTypes
using Unitful
import Distributions

using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

# @testset "Makie" begin

    function test_1d_plot(plot_function, dd)
        x = lookup(dd, 1)
        y = collect(parent(dd))
        fig_dd, ax_dd, plt_dd = plot_function(dd)

        dd_obs = Observable(dd)
        fig_dd, ax_dd, plt_obs_dd = plot_function(dd_obs)

        dd_obs_2 = @lift identity($dd_obs)

        fig_dd, ax_dd, plt_obs_dd_2 = plot_function(dd_obs_2)
        
        init_test = (first.(plt_obs_dd_2[1][]) == ustrip.(x) &&
            last.(plt_obs_dd_2[1][]) == ustrip.(y))
        dd .*= 2
        notify(dd_obs)

        (first.(plt_dd[1][]) == ustrip.(x) &&
            last.(plt_dd[1][]) == ustrip.(y) && 
            first.(plt_obs_dd[1][]) == ustrip.(x) && 
            last.(plt_obs_dd[1][]) == ustrip.(y .* 2) &&
            init_test &&
            first.(plt_obs_dd_2[1][]) == ustrip.(x) &&
            last.(plt_obs_dd_2[1][]) == ustrip.(parent(dd))
        )
    end

    # 1d
    A1 = rand(X('a':'e'); name=:test)
    A1m = rand([missing, (1:3.)...], X('a':'e'); name=:test)
    A1u = rand([missing, (1:3.)...], X(1u"s":1u"s":3u"s"); name=:test)
    A1ui = rand([missing, (1:3.)...], X(1u"s":1u"s":3u"s"; sampling=Intervals(Start())); name=:test)
    A1num = rand(X(-10:10))

    @test test_1d_plot(lines, A1num)
    @test test_1d_plot(lines, rand(Y(-1:1)))
    @test test_1d_plot(lines, rand(Y(-1s:0.5s:1s)))
    @test test_1d_plot(lines, A1)
    # @test test_1d_plot(lines, A1m)  Does not work because of `chars` X axis
    @test test_1d_plot(lines, A1u)
    # @test test_1d_plot(lines, A1ui) Does not pass because intervals


    A1m .= A1
    A1m[3] = missing
    fig, ax, _ = plot(A1)
    plot!(ax, A1)
    fig, ax, _ = plot(A1m)
    fig, ax, _ = plot(parent(A1m))
    plot!(ax, A1m)
    fig, ax, _ = plot(A1u)
    plot!(ax, A1u)
    fig, ax, _ = plot(A1ui)
    plot!(ax, A1ui)
    fig, ax, _ = plot(A1num)
    reset_limits!(ax)
    org = first(ax.finallimits.val.origin)
    wid = first(widths(ax.finallimits.val))
    # This tests for #714
    @test org <= -10
    @test org + wid >= 10

    ## Scatter 
    
    @test test_1d_plot(scatter, A1)
    @test test_1d_plot(scatter, A1num)
    @test test_1d_plot(scatter, A1u)

    fig, ax, _ = scatter(A1)
    scatter!(ax, A1)
    fig, ax, _ = scatter(A1m)
    scatter!(ax, A1m)
    fig, ax, _ = lines(A1)
    lines!(ax, A1)
    fig, ax, _ = lines(A1u)
    lines!(ax, A1u)
    fig, ax, _ = lines(A1m)
    lines!(ax, A1m)

    @test test_1d_plot(scatterlines, A1)
    @test test_1d_plot(scatterlines, A1num)
    @test test_1d_plot(scatterlines, A1u)
    fig, ax, _ = scatterlines(A1)
    scatterlines!(ax, A1)
    fig, ax, _ = scatterlines(A1u)
    scatterlines!(ax, A1u)
    fig, ax, _ = scatterlines(A1m)
    scatterlines!(ax, A1m)


    @test test_1d_plot(stairs, A1)
    @test test_1d_plot(stairs, A1num)
    @test test_1d_plot(stairs, A1u)
    fig, ax, _ = stairs(A1)
    stairs!(ax, A1)
    fig, ax, _ = stairs(A1u)
    stairs!(ax, A1u)
    fig, ax, _ = stairs(A1m)
    stairs!(ax, A1m)

    @test test_1d_plot(stem, A1)
    @test test_1d_plot(stem, A1num)
    @test test_1d_plot(stem, A1u)
    fig, ax, _ = stem(A1)
    stem!(ax, A1)
    fig, ax, _ = stem(A1u)
    stem!(ax, A1u)
    fig, ax, _ = stem(A1m)
    stem!(ax, A1m)

    @test test_1d_plot(barplot, A1)
    @test test_1d_plot(barplot, A1num)
    @test test_1d_plot(barplot, A1u)
    fig, ax, _ = barplot(A1)
    barplot!(ax, A1)
    fig, ax, _ = barplot(A1u)
    barplot!(ax, A1u)
    fig, ax, _ = barplot(A1m)
    barplot!(ax, A1m)

    @test test_1d_plot(waterfall, A1)
    @test test_1d_plot(waterfall, A1num)
    @test test_1d_plot(waterfall, A1u)
    fig, ax, _ = waterfall(A1)
    waterfall!(ax, A1)
    fig, ax, _ = waterfall(A1u)
    waterfall!(ax, A1u)
    fig, ax, _ = waterfall(A1m)
    waterfall!(ax, A1m)

    # 2d
    A2 = rand(X(10:10:100), Y(['a', 'b', 'c']))
    A2r = rand(Y(10:10:100), X(['a', 'b', 'c']))
    A2m = rand([missing, (1:5)...], Y(10:10:100), X(['a', 'b', 'c']))
    A2u = rand(Y(10u"km":10u"km":100u"km"), X(['a', 'b', 'c']))
    A2ui = rand(Y(10u"km":10u"km":100u"km"; sampling=Intervals(Start())), X(['a', 'b', 'c']))
    A2m[3] = missing
    A2rgb = rand(RGB, X(10:10:100), Y(['a', 'b', 'c']))

    #Test whether the conversion functions work
    #TODO once surface2 is corrected to use the plottrait this should
    #already be tested with the usual plotting functions
    M.convert_arguments(M.CellGrid(), A2)
    M.convert_arguments(M.VertexGrid(), A2)
    M.convert_arguments(M.ImageLike(), A2)

    M.convert_arguments(M.CellGrid(), A2u)
    M.convert_arguments(M.VertexGrid(), A2u)
    M.convert_arguments(M.ImageLike(), A2u)


    ## Does not pass as is plotted in interval and observable gives a different plot
    #@test test_2d_plot(M.heatmap, A2num)
    #@test test_2d_plot(heatmap, A2numu)


    fig, ax, _ = plot(A2)
    plot!(ax, A2)
    fig, ax, _ = plot(A2m)
    plot!(ax, A2m)
    fig, ax, _ = plot(A2u)
    plot!(ax, A2u)
    fig, ax, _ = plot(A2ui)
    plot!(ax, A2ui)
    fig, ax, _ = plot(A2rgb)
    plot!(ax, A2rgb)
    fig, ax, _ = heatmap(A2)
    heatmap!(ax, A2)
    fig, ax, _ = heatmap(A2m)
    heatmap!(ax, A2m)
    fig, ax, _ = heatmap(A2rgb)
    heatmap!(ax, A2rgb)

    fig, ax, _ = image(A2)
    image!(ax, A2)
    fig, ax, _ = image(A2m)
    image!(ax, A2m)
    fig, ax, _ = image(A2rgb)
    image!(ax, A2rgb)
    fig, ax, _ = violin(A2r)
    violin!(ax, A2r)
    @test_throws ArgumentError violin(A2m)
    @test_throws ArgumentError violin!(ax, A2m)

    fig, ax, _ = rainclouds(A2)
    rainclouds!(ax, A2)
    fig, ax, _ = rainclouds(A2u)
    rainclouds!(ax, A2u)
    @test_throws ErrorException rainclouds(A2m) # MethodError ? missing values in data not supported

    fig, ax, _ = surface(A2)
    surface!(ax, A2)
    fig, ax, _ = surface(A2u)
    surface!(ax, A2u)
    fig, ax, _ = surface(A2ui)
    surface!(ax, A2ui)
    # Broken with missing
    # fig, ax, _ = surface(A2m)
    # surface!(ax, A2m)
    # Series also puts Categories in the legend no matter where they are
    # TODO: method series! is incomplete, we need to include the colors logic, as in series. There should not be any issue if the correct amount of colours is provided.
    fig, ax, _ = series(A2)
    series!(ax, A2)
    fig, ax, _ = series(A2u)
    series!(ax, A2u)
    fig, ax, _ = series(A2ui)
    series!(ax, A2u)
    fig, ax, _ = series(A2r)
    series!(ax, A2r)
    fig, ax, plt = series(A2r; labeldim=Y)
    
    A2numu = rand(X(10u"s":10u"s":100u"s"), Y(1u"V":1u"V":3u"V"))
    fig, ax, plt = series(A2numu; labeldim=Y)
    coords = stack(stack(plt[1][]))
    @test all(coords[1,:,:] .== ustrip(lookup(A2numu, X)))
    @test all(coords[2,:,:] .== parent(A2numu))

    # series!(ax, A2r; labeldim=Y)
    fig, ax, _ = series(A2m)
    series!(ax, A2m)
    @test_throws ArgumentError plot(A2; y=:c)
    @test_throws ArgumentError plot!(ax, A2; y=:c)

    # x/y can be specifie
    A2ab = DimArray(rand(6, 10), (:a, :b); name=:stuff)
    fig, ax, _ = plot(A2ab)
    plot!(ax, A2ab)
    fig, ax, _ = contourf(A2ab; x=:a)
    contourf!(ax, A2ab, x=:a)
    fig, ax, _ = heatmap(A2ab; y=:b)
    heatmap!(ax, A2ab; y=:b)
    fig, ax, _ = series(A2ab)
    series!(ax, A2ab)
    fig, ax, _ = boxplot(A2ab)
    boxplot!(ax, A2ab)
    fig, ax, _ = violin(A2ab)
    violin!(ax, A2ab)
    fig, ax, _ = rainclouds(A2ab)
    rainclouds!(ax, A2ab)
    fig, ax, _ = surface(A2ab)
    surface!(ax, A2ab)
    fig, ax, _ = series(A2ab)
    series!(ax, A2ab)
    fig, ax, _ = series(A2ab; labeldim=:a)
    series!(ax, A2ab; labeldim=:a)

    fig, ax, _ = series(A2ab; labeldim=:b)
    # series!(ax, A2ab;labeldim=:b)

    # 3d, all these work with GLMakie
    A3 = rand(X(7), Z(10), Y(5))
    A3u = rand(X((1:7)u"m"), Z((1.0:1:10.0)u"m"), Y((1:5)u"g"))
    A3m = rand([missing, (1:7)...], X(7), Z(10), Y(5))
    A3m[3] = missing
    A3rgb = rand(RGB, X(7), Z(10), Y(5))
    fig, ax, _ = volume(A3)
    volume!(ax, A3)
    fig, ax, _ = volume(A3m)
    volume!(ax, A3m)

    # Units are broken in Makie ?
    # fig, ax, _ = volume(A3u)
    # volume!(ax, A3u)

    fig, ax, _ = volumeslices(A3)
    volumeslices!(ax, A3)
    # Need to manually specify colorrange
    fig, ax, _ = volumeslices(A3m; colorrange=(1, 7))
    volumeslices!(ax, A3m; colorrange=(1, 7))

    # Unitful volumeslices broken in Makie ?
    # fig, ax, _ = volumeslices(A3u)
    # volumeslices!(ax, A3u)

    # RGB volumeslices broken in Makie ?
    # fig, ax, _ = volumeslices(A3rgb)
    # volumeslices!(ax, A3rgb)
    # fig, ax, _ = volumeslices(A3rgb)
    # volumeslices!(ax, A3rgb)
    # x/y/z can be specified
    A3abc = DimArray(rand(10, 10, 7), (:a, :b, :c); name=:stuff)
    fig, ax, _ = volume(A3abc; x=:c)
    # fig, ax, _ = volumeslices(A3abc; x=:c)
    # fig, ax, _ = volumeslices(A3abc; z=:a)
    # volumeslices!(ax, A3abc;z=:a)

    @testset "LScene support" begin
        f, a, p = heatmap(A2ab; axis = (; type = LScene, show_axis = false))
        @test a isa LScene
        @test isnothing(a.scene[OldAxis])
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
