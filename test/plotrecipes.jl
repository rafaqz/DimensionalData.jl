using DimensionalData, Test, Dates
using Unitful
import Distributions

using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End


@testset "Plots.jl" begin

using Plots
using StatsPlots

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
da3_XTiZ = DimArray(A3, (X(1:10:400), Ti(1u"s":5u"s":100u"s"), Z(1:10:100)); name=:Normal)
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


@testset "Makie" begin

    using CairoMakie: CairoMakie as M
    using ColorTypes

    # 1d
    A1 = rand(X('a':'e'); name=:test)
    A1m = rand([missing, (1:3.)...], X('a':'e'); name=:test)
    A1u = rand([missing, (1:3.)...], X(1u"s":1u"s":3u"s"); name=:test)
    A1ui = rand([missing, (1:3.)...], X(1u"s":1u"s":3u"s"; sampling=Intervals(Start())); name=:test)
    A1num = rand(X(-10:10))
    A1m .= A1
    A1m[3] = missing
    fig, ax, _ = M.plot(A1)
    M.plot!(ax, A1)
    fig, ax, _ = M.plot(A1m)
    fig, ax, _ = M.plot(parent(A1m))
    M.plot!(ax, A1m)
    fig, ax, _ = M.plot(A1u)
    M.plot!(ax, A1u)
    fig, ax, _ = M.plot(A1ui)
    M.plot!(ax, A1ui)
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
    M.lines!(ax, A1u)
    fig, ax, _ = M.lines(A1m)
    M.lines!(ax, A1m)
    fig, ax, _ = M.scatterlines(A1)
    M.scatterlines!(ax, A1)
    fig, ax, _ = M.scatterlines(A1u)
    M.scatterlines!(ax, A1u)
    fig, ax, _ = M.scatterlines(A1m)
    M.scatterlines!(ax, A1m)
    fig, ax, _ = M.stairs(A1)
    M.stairs!(ax, A1)
    fig, ax, _ = M.stairs(A1u)
    M.stairs!(ax, A1u)
    fig, ax, _ = M.stairs(A1m)
    M.stairs!(ax, A1m)
    fig, ax, _ = M.stem(A1)
    M.stem!(ax, A1)
    fig, ax, _ = M.stem(A1u)
    M.stem!(ax, A1u)
    fig, ax, _ = M.stem(A1m)
    M.stem!(ax, A1m)
    fig, ax, _ = M.barplot(A1)
    M.barplot!(ax, A1)
    fig, ax, _ = M.barplot(A1u)
    M.barplot!(ax, A1u)
    fig, ax, _ = M.barplot(A1m)
    M.barplot!(ax, A1m)
    fig, ax, _ = M.waterfall(A1)
    M.waterfall!(ax, A1)
    fig, ax, _ = M.waterfall(A1u)
    M.waterfall!(ax, A1u)
    fig, ax, _ = M.waterfall(A1m)
    M.waterfall!(ax, A1m)

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

    fig, ax, _ = M.plot(A2)
    M.plot!(ax, A2)
    fig, ax, _ = M.plot(A2m)
    M.plot!(ax, A2m)
    fig, ax, _ = M.plot(A2u)
    M.plot!(ax, A2u)
    fig, ax, _ = M.plot(A2ui)
    M.plot!(ax, A2ui)
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
    fig, ax, _ = M.surface(A2u)
    M.surface!(ax, A2u)
    fig, ax, _ = M.surface(A2ui)
    M.surface!(ax, A2ui)
    # Broken with missing
    # fig, ax, _ = M.surface(A2m)
    # M.surface!(ax, A2m)
    # Series also puts Categories in the legend no matter where they are
    # TODO: method series! is incomplete, we need to include the colors logic, as in series. There should not be any issue if the correct amount of colours is provided.
    fig, ax, _ = M.series(A2)
    # M.series!(ax, A2)
    fig, ax, _ = M.series(A2u)
    # M.series!(ax, A2u)
    fig, ax, _ = M.series(A2ui)
    # M.series!(ax, A2u)
    fig, ax, _ = M.series(A2r)
    # M.series!(ax, A2r)
    fig, ax, _ = M.series(A2r; labeldim=Y)
    # M.series!(ax, A2r; labeldim=Y)
    fig, ax, _ = M.series(A2m)
    # M.series!(ax, A2m)
    @test_throws ArgumentError M.plot(A2; y=:c)
    # @test_throws ArgumentError M.plot!(ax, A2; y=:c)

    # x/y can be specified
    A2ab = DimArray(rand(6, 10), (:a, :b); name=:stuff)
    fig, ax, _ = M.plot(A2ab)
    M.plot!(ax, A2ab)
    fig, ax, _ = M.contourf(A2ab; x=:a)
    M.contourf!(ax, A2ab, x=:a)
    fig, ax, _ = M.heatmap(A2ab; y=:b)
    M.heatmap!(ax, A2ab; y=:b)
    fig, ax, _ = M.series(A2ab)
    M.series!(ax, A2ab)
    fig, ax, _ = M.boxplot(A2ab)
    M.boxplot!(ax, A2ab)
    fig, ax, _ = M.violin(A2ab)
    M.violin!(ax, A2ab)
    fig, ax, _ = M.rainclouds(A2ab)
    M.rainclouds!(ax, A2ab)
    fig, ax, _ = M.surface(A2ab)
    M.surface!(ax, A2ab)
    fig, ax, _ = M.series(A2ab)
    M.series!(ax, A2ab)
    fig, ax, _ = M.series(A2ab; labeldim=:a)
    M.series!(ax, A2ab; labeldim=:a)

    fig, ax, _ = M.series(A2ab; labeldim=:b)
    # M.series!(ax, A2ab;labeldim=:b)

    # 3d, all these work with GLMakie
    A3 = rand(X(7), Z(10), Y(5))
    A3u = rand(X((1:7)u"m"), Z((1.0:1:10.0)u"m"), Y((1:5)u"g"))
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
    fig, ax, _ = M.volume(A3abc; x=:c)
    # fig, ax, _ = M.volumeslices(A3abc; x=:c)
    # fig, ax, _ = M.volumeslices(A3abc; z=:a)
    # M.volumeslices!(ax, A3abc;z=:a)

    @testset "LScene support" begin
        f, a, p = M.heatmap(A2ab; axis = (; type = M.LScene, show_axis = false))
        @test a isa M.LScene
        @test isnothing(a.scene[M.OldAxis])
    end
end

@testset "AlgebraOfGraphics" begin
    using AlgebraOfGraphics, CairoMakie
    using DimensionalData

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
