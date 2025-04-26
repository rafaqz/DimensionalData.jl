using DimensionalData, Test, Dates
using AlgebraOfGraphics
using CairoMakie
using ColorTypes
using Unitful
import Distributions
import DimensionalData as DD

using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

x = 1:5
y = x.^2
dd_vec = DimArray(y, Ti(x), name=:test)
dd_char_vec = DimArray(y, X(Char.(70:74)), name=:test)
dd_vec_mis = DimArray([missing, 1, 2, 3, 4, 5], X('A':'F'), name= "string title")
dd_vec_uni = DimArray(collect(x).*u"mm", X(x .* u"F"), name= "string title")

function test_1d_plot(plot_function, _dd)
    dd = deepcopy(_dd)
    x = parent(lookup(dd, 1))
    y = collect(parent(dd))
    fig_dd, ax_dd, plt_dd = plot_function(dd)

    dd_obs = Observable(dd)
    fig_dd, ax_dd, plt_obs_dd = plot_function(dd_obs)
    
    init_test = check_plotted_data(plt_obs_dd, dd_obs) &&
        check_plotted_data(plt_dd, dd)
    dd .*= 2
    notify(dd_obs)

    if !(eltype(x) <: AbstractChar)
        x_obs = Observable(collect(x))
        y_obs = Observable(y)
        dd_obs_x = @lift DimArray($y_obs, X($x_obs), name=:test)
        fig_dd, ax_dd_x, plt_obs_dd_x = plot_function(dd_obs_x)


        x_obs[] .*= 2
        notify(x_obs)
        init_test &= check_plotted_data(plt_obs_dd_x, dd_obs_x)
    end

    (
        init_test &&
        check_plotted_data(plt_obs_dd, dd_obs) &&
        ax_dd.title[] == DD.refdims_title(dd) &&
        ax_dd.xlabel[] == DD.label(DD.dims(dd, 1)) &&
        ax_dd.ylabel[] == DD.label(dd)
    )
end

function check_plotted_data(plt::Union{Makie.Lines, Makie.Scatter, Makie.BarPlot, Makie.ScatterLines, Makie.LineSegments}, data) 
    if false
        @show first.(plt[1][])
        @show get_numerical_data(parent(lookup(to_value(data), 1)))
        @show last.(plt[1][])
        @show replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))
    end
    all(first.(plt[1][]) .≈ get_numerical_data(parent(lookup(to_value(data), 1)))) && 
        all(my_approx.(last.(plt[1][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function check_plotted_data(plt::Union{BoxPlot, RainClouds, Violin}, data)
    all(plt[1][] .≈ get_numerical_data(parent(lookup(to_value(data), 1)))) && 
        all(my_approx.(plt[2][], replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function my_approx(x, y)
    if x === y === NaN
        return true
    else 
        x ≈ y
    end
end
get_numerical_data(x::AbstractVector{<:AbstractChar}) = Int.(x)
get_numerical_data(x::AbstractVector{<:Union{Number, Missing}}) = x
get_numerical_data(x::AbstractVector{<:Unitful.Quantity}) = ustrip.(x)

for dd_i in (dd_vec, dd_vec_uni, dd_vec_mis, dd_char_vec)
    @test test_1d_plot(lines, dd_i)
    @test test_1d_plot(scatter, dd_i)
    @test test_1d_plot(scatterlines, dd_i)
    @test test_1d_plot(linesegments, dd_i)
end

dd_cat = DimArray(rand(6), X(cat(fill('A', 3), fill('B', 3), dims = 1)), name = :test)
for dd_i in (dd_vec, dd_cat, dd_char_vec) # These plot do not work with missing and unitful due to Makie limitations
    @test test_1d_plot(rainclouds, dd_i)
    @test test_1d_plot(violin, dd_i)
    @test test_1d_plot(boxplot, dd_i)
end

### Series tests
dd_mat = rand(X(5:10), Y(1:5))
dd_mat_cat = rand(X(5:10), Y('A':'E'))
a,b,c = series(dd_mat)


function test_series(_dd; labeldim)
    dd = deepcopy(_dd)
    x = parent(lookup(dd, 1))
    y = collect(parent(dd))
    fig_dd, ax_dd, plt_dd = series(dd, labeldim = labeldim)

    dd_obs = Observable(dd)
    fig_dd, ax_dd, plt_obs_dd = series(dd_obs, labeldim = labeldim)
    
    init_test = check_plotted_data(plt_obs_dd, dd_obs; labeldim = labeldim) &&
        check_plotted_data(plt_dd, dd, labeldim = labeldim)
    dd .*= 2
    notify(dd_obs)

    (
        init_test &&
        check_plotted_data(plt_obs_dd, dd_obs, labeldim = labeldim) &&
        ax_dd.title[] == DD.refdims_title(dd) &&
        ax_dd.xlabel[] == DD.label(DD.otherdims(dd, labeldim)[1]) &&
        ax_dd.ylabel[] == DD.label(dd)
    )
end

function check_plotted_data(plt::Series, data; labeldim)
    otherdim = DD.otherdims(to_value(data), labeldim)[1]
    per_data = permutedims(to_value(data), (otherdim, labeldim))
    x = get_numerical_data(parent(lookup(to_value(per_data), 1)))
    cond = true
    for i in 1:size(per_data, 2)
        if true 
            @show first.(plt[1][][i])
            @show x
            @show last.(plt[1][][i])
            @show replace(float.(get_numerical_data(parent(to_value(per_data[:,i])))), missing => float(NaN))
        end
        if !(all(first.(plt[1][][i]) .≈ x) && 
            all(my_approx.(last.(plt[1][][i]), replace(float.(get_numerical_data(parent(to_value(per_data[:,i])))), missing => float(NaN)))))
            cond = false
        end
    end
    cond
end

dd_mat_cat = DimArray(rand(2, 3), (Y('a':'b'), X(1:3)); name = :test)
dd_mat_num = DimArray(rand(2, 3), (Y(1:2), X(1:3)); name = :test)
dd_mat_uni = DimArray(rand(2, 3) .* u"m", (Y((1:2) .* u"s"), X((1:3) .* u"F")); name = :test)
dd_mat_mis = DimArray([missing 1 2; missing 1 2], (Y(1:2), X(1:3)); name = :test)
for dd_i in (dd_mat_cat, dd_mat_num, dd_mat_mis) # Unit does not work because of Makie recursion limitations
    @test test_series(dd_i; labeldim = Y)
    @test test_series(dd_i; labeldim = X)
end
_, _, plt = series(dd_mat_ser)
@test first.(plt[1][][1]) == lookup(dd_mat_ser, X) # check that automatic label dim detection chooses categorical on labeldim


function test_keywords_used(plt_type, dd; axis = (;), kwargs...)
    fig, ax, plt = plt_type(dd; axis = axis, kwargs...)
    cond = true
    for i in keys(axis)
        (axis[i] != to_value(getproperty(ax, i))) && (cond = false)
    end
    for i in keys(kwargs)
        (kwargs[i] != to_value(getproperty(plt, i))) && (cond = false)
    end
    cond
end

@test test_keywords_used(lines, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), linewidth = 2, color = :red, label = "new_label")
@test test_keywords_used(scatter, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), markersize = 2, color = :red, label = "new_label")
@test test_keywords_used(scatterlines, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), marker = Circle, color = :red, label = "new_label")
@test test_keywords_used(linesegments, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, linestyle = :dash, label = "new_label")
@test test_keywords_used(series, dd_mat_cat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), linestyle = :dash, label = "new_label")

@test test_keywords_used(rainclouds, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")
@test test_keywords_used(violin, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")
@test test_keywords_used(boxplot, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")

name = Observable(:test)
dd = @lift DimArray(y, X(x), name=$name)
fig, ax, plt = lines(dd)
name[] = :test_2
@test to_value(plt.label) == string(name[]) # For some reason, it updates the value but not display value in the figure. This is a Makie issue as replicable without DimArray
@test to_value(ax.ylabel) == string(name[])

dd_mat = rand(X(5:10), Y(1:5))
dd_3d = rand(X(1:5), Y(1:5), Z(1:5))

a, b, c = contour(dd_mat)
contourf(dd_mat)
contour3d(dd_mat)
heatmap(dd_mat)
image(dd_mat)
series(dd_mat)
spy(dd_mat)
stairs(dd_vec)
stem(dd_vec)
stephist(dd_vec) # should give error?
surface(dd_mat)
violin(dd_vec)
volume(dd_3d)
volumeslices(dd_3d)
waterfall(dd_vec)
# @testset "Makie" begin


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
