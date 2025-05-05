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

function test_3d_plot(plot_function, _dd; x, y, z)
    dd = copy(_dd)
    x_val = parent(lookup(dd, 1))
    y_val = parent(lookup(dd, 2))
    z_val = parent(lookup(dd, 3))
    data_val = collect(parent(dd))
    fig_dd, ax_dd, plt_dd = plot_function(dd; x = x, y = y, z = z)

    dd_obs = Observable(dd)
    fig_dd, ax_dd, plt_obs_dd = plot_function(dd_obs; x = x, y = y, z = z)


    init_test = check_plotted_data(plt_obs_dd, dd_obs, x = x, y = y, z = z) &&
        check_plotted_data(plt_dd, dd, x = x, y = y, z = z)
    dd .*= 2
    notify(dd_obs)
    if !(any(i -> eltype(i) <: AbstractChar, (x_val, y_val, z_val)) || plot_function in (image, heatmap, spy))
        # Check that observable on x, y, z works fine
        x_obs = Observable(deepcopy(x_val) .* 1)
        y_obs = Observable(y_val .* 1)
        z_obs = Observable(z_val .* 1)
        data_obs = Observable(data_val)
        dd_obs_x = @lift DimArray($data_obs, (x($x_obs), y($y_obs), z($z_obs)), name=:test)
        fig_dd, ax_dd_x, plt_obs_dd_x = plot_function(dd_obs_x, x = x, y = y, z = z)

        x_obs[] = x_val .* 2
        y_obs[] = y_val .* 3
        z_obs[] = z_val .* 3
        notify(x_obs)
        init_test &= check_plotted_data(plt_obs_dd_x, dd_obs_x, x = x, y = y, z = z)
    end
    (
        init_test &&
        check_plotted_data(plt_obs_dd, dd_obs, x = x, y = y, z = z)
    )
end

function check_plotted_data(plt::Volume, _data; x, y, z) 
    data = permutedims(to_value(_data), (x, y, z))
    x_val = parent(lookup(to_value(data), x)) |> get_numerical_data
    y_val = parent(lookup(to_value(data), y)) |> get_numerical_data
    z_val = parent(lookup(to_value(data), z)) |> get_numerical_data
    all(plt[1][] .≈ range_to_endpoints(x_val)) &&
        all(plt[2][] .≈ range_to_endpoints(y_val)) &&
        all(plt[3][] .≈ range_to_endpoints(z_val)) &&
        all(my_approx.(last.(plt[4][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function check_plotted_data(plt::VolumeSlices, _data; x, y, z) 
    data = permutedims(to_value(_data), (x, y, z))
    x_val = parent(lookup(to_value(data), x)) |> get_numerical_data
    y_val = parent(lookup(to_value(data), y)) |> get_numerical_data
    z_val = parent(lookup(to_value(data), z)) |> get_numerical_data
    all(plt[1][] .≈ x_val) &&
        all(plt[2][] .≈ y_val) &&
        all(plt[3][] .≈ z_val) &&
        all(my_approx.(last.(plt[4][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function range_to_endpoints(x::AbstractRange)
    (x[1] - step(x) / 2, x[end] + step(x) / 2)
end,
function range_to_endpoints(x::AbstractVector)
    allequal(i -> round(i, digits = 6), diff(x)) || error()
    step_x = x[2] - x[1]
    (x[1] - step_x / 2, x[end] + step_x / 2)
end


function test_2d_plot(plot_function, _dd; x, y)
    dd = deepcopy(_dd)
    x_val = parent(lookup(dd, 1))
    y_val = parent(lookup(dd, 2))
    z_val = collect(parent(dd))
    fig_dd, ax_dd, plt_dd = plot_function(dd; x = x, y = y)

    dd_obs = Observable(dd)
    fig_dd, ax_dd, plt_obs_dd = plot_function(dd_obs; x = x, y = y)

    init_test = check_plotted_data(plt_obs_dd, dd_obs, x = x, y = y) &&
        check_plotted_data(plt_dd, dd, x = x, y = y)
    dd .*= 2
    notify(dd_obs)
    if !(any(i -> eltype(i) <: Union{AbstractChar, Symbol}, (x_val, y_val, z_val)) || plot_function in (image, heatmap, spy))
        x_obs = Observable(collect(x_val))
        y_obs = Observable(y_val)
        z_obs = Observable(z_val)
        dd_obs_x = @lift DimArray($z_obs, (x($x_obs), y($y_obs)), name=:test)
        fig_dd, ax_dd_x, plt_obs_dd_x = plot_function(dd_obs_x, x = x, y = y)

        x_obs[] .*= 2
        notify(x_obs)
        init_test &= check_plotted_data(plt_obs_dd_x, dd_obs_x, x = x, y = y)
    end

    (
        init_test &&
        check_plotted_data(plt_obs_dd, dd_obs, x = x, y = y)
    )
end

function check_plotted_data(plt::Union{Contour, Contourf, Surface, Contour3d}, _data; x, y) 
    data = permutedims(to_value(_data), (x, y))
    all(plt[1][] .≈ get_numerical_data(parent(lookup(to_value(data), x)))) && 
        all(plt[2][] .≈ get_numerical_data(parent(lookup(to_value(data), y)))) && 
        all(my_approx.(last.(plt[3][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function check_plotted_data(plt::Union{Image, Spy}, _data; x, y) 
    data = permutedims(to_value(_data), (x, y))
    all(plt[1][] .≈ extrema(parent(lookup(to_value(data), x))) .+ (step(lookup(to_value(data), x)) .* (-.5, +.5 ))) && 
        all(plt[2][] .≈ extrema(parent(lookup(to_value(data), y))) .+ (step(lookup(to_value(data), y)) .* (-.5, .5))) && 
        all(my_approx.(last.(plt[3][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function check_plotted_data(plt::Union{Heatmap}, _data; x, y) 
    data = permutedims(to_value(_data), (x, y))
    x_val = parent(lookup(to_value(data), x)) |> get_numerical_data
    y_val = parent(lookup(to_value(data), y)) |> get_numerical_data
    all(plt[1][] .≈ vcat([x_val[1] - step(x_val) / 2], x_val .+ step(x_val) / 2)) && 
        all(plt[2][] .≈ vcat([y_val[1] - step(y_val) / 2], y_val .+ step(y_val) / 2)) && 
        all(my_approx.(last.(plt[3][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

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

function has_colorbar(plot_function, A2ab)
    fig, ax, _ = plot_function(A2ab)
    colorbars = filter(x -> x isa Colorbar, fig.content)

    A2ab_unnamed = DimArray(parent(A2ab), DD.dims(A2ab))
    fig, ax, _ = plot_function(A2ab_unnamed)
    colorbars_unnamed = filter(x -> x isa Colorbar, fig.content)
    length(colorbars_unnamed) == 1 && 
        colorbars_unnamed[1].label[] == DD.label(A2ab_unnamed) &&
        length(colorbars) == 1 &&
        colorbars[1].label[] == DD.label(A2ab)
end

function test_1d_plot(plot_function, _dd)
    dd = deepcopy(_dd)
    x = parent(lookup(dd, 1))
    y = collect(parent(dd))
    fig_dd, ax_dd, plt_dd = plot_function(dd)

    dd_obs = Observable(dd)
    fig_dd, ax_obs_dd, plt_obs_dd = plot_function(dd_obs)

    init_test = check_plotted_data(plt_obs_dd, dd_obs) &&
        check_plotted_data(plt_dd, dd) &&
        check_plot_attributes(ax_dd, plt_dd, dd)
        check_plot_attributes(ax_obs_dd, plt_obs_dd, dd_obs)
    dd .*= 2
    notify(dd_obs)

    if !(eltype(x) <: Union{AbstractChar, Symbol}) # Test if change in x axis of observable works
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
        check_plotted_data(plt_obs_dd, dd_obs)
    )
end

function check_plot_attributes(ax, plt::Union{Makie.Lines, Makie.Scatter, Makie.BarPlot, Makie.ScatterLines, Makie.LineSegments, Violin, RainClouds, BoxPlot, Stairs, Waterfall, Stem}, _dd) 
    dd = to_value(_dd)
    ax.title[] == DD.refdims_title(dd) &&
    ax.xlabel[] == DD.label(DD.dims(dd, 1)) &&
    ax.ylabel[] == DD.label(dd)
    plt.label[] == DD.label(dd)
end

function check_plotted_data(plt::Union{Makie.Lines, Makie.Scatter, Makie.BarPlot, Makie.ScatterLines, Makie.LineSegments, Waterfall, Stem, Stairs}, data) 
    all(first.(plt[1][]) .≈ get_numerical_data(parent(lookup(to_value(data), 1)))) && 
        all(my_approx.(last.(plt[1][]), replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function check_plotted_data(plt::Union{BoxPlot, RainClouds, Violin}, data)
    all(plt[1][] .≈ get_numerical_data(parent(lookup(to_value(data), 1)))) && 
        all(my_approx.(plt[2][], replace(float.(get_numerical_data(parent(to_value(data)))), missing => float(NaN))))
end

function my_approx(x, y)
    if Float32(x) === Float32(y) === NaN32
        return true
    else 
        Float32(x) ≈ Float32(y)
    end
end
get_numerical_data(x::AbstractArray{<:AbstractChar}) = Int.(x)
get_numerical_data(x::AbstractArray{<:Union{Number, Missing}}) = x
get_numerical_data(x::AbstractArray{<:Unitful.Quantity}) = ustrip.(x)
get_numerical_data(x::AbstractVector{<:AbstractString}) = sum.(Int, x) # Sum all chars
get_numerical_data(x::AbstractVector{<:Symbol}) = get_numerical_data(string.(x))

@testset begin 
    x = 1:5
    y = x.^2
    dd_vec = DimArray(y, Ti(x), name=:test)
    dd_char_vec = DimArray(y, X(Char.(70:74)), name=:test)
    dd_symbol_vec = DimArray(y, X(Symbol.(Char.(70:74))), name=:test)
    dd_vec_mis = DimArray([missing, 1, 2, 3, 4, 5], X('A':'F'), name= "string title")
    dd_vec_uni = DimArray(collect(x).*u"mm", X(x .* u"F"), name= "string title")


    for dd_i in (dd_vec, dd_vec_uni, dd_vec_mis, dd_char_vec, dd_symbol_vec)
        @test test_1d_plot(lines, dd_i)
        @test test_1d_plot(scatter, dd_i)
        @test test_1d_plot(scatterlines, dd_i)
        @test test_1d_plot(linesegments, dd_i)
        @test test_1d_plot(stairs, dd_i)
        @test test_1d_plot(stem, dd_i)
        @test test_1d_plot(waterfall, dd_i)
        @test test_1d_plot(plot, dd_i)
    end

    dd_cat = DimArray(rand(6), X(cat(fill('A', 3), fill('B', 3), dims = 1)), name = :test)
    for dd_i in (dd_vec, dd_cat, dd_char_vec) 
        @test test_1d_plot(rainclouds, dd_i)
        @test test_1d_plot(violin, dd_i)
        @test test_1d_plot(boxplot, dd_i)
    end

    for dd_i in (dd_vec_mis, dd_vec_uni) # These plot do not work with missing and unitful due to Makie limitations
        @test test_1d_plot(rainclouds, dd_i) broken = true
        @test test_1d_plot(violin, dd_i) broken = true
        @test test_1d_plot(boxplot, dd_i) broken = true
    end

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
            if !(all(first.(plt[1][][i]) .≈ x) && 
                all(my_approx.(last.(plt[1][][i]), replace(float.(get_numerical_data(parent(to_value(per_data[:,i])))), missing => float(NaN)))))
                cond = false
            end
        end
        cond
    end

    dd_mat_cat = DimArray(rand(2, 3), (Y('a':'b'), X(1:3)); name = :test)
    dd_mat_sym = DimArray(rand(2, 3), (Y(Symbol.('a':'b')), X(1:3)); name = :test)
    dd_mat_num = DimArray(rand(2, 3), (Y(1:2), X(1:3)); name = :test)
    dd_mat_uni = DimArray(rand(2, 3) .* u"m", (Y((1:2) .* u"s"), X((1:3) .* u"F")); name = :test)
    dd_mat_mis = DimArray([missing 1 2; missing 1 2], (Y(1:2), X(1:3)); name = :test)
    for dd_i in (dd_mat_cat, dd_mat_num, dd_mat_mis, dd_mat_sym) 
        @test test_series(dd_i; labeldim = Y)
        @test test_series(dd_i; labeldim = X)
    end

    @test test_series(dd_i; labeldim = Y) broken = true # Does not work because of issue #4946 of Makie
    @test test_series(dd_i; labeldim = X) broken = true # Does not work because of issue #4946 of Makie

    _, _, plt = series(dd_mat_cat)
    @test first.(plt[1][][1]) == lookup(dd_mat_cat, X) # check that automatic label dim detection chooses categorical on labeldim

    # Test if the attributes can be overwritten by user input
    @test test_keywords_used(lines, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), linewidth = 2, color = :red, label = "new_label")
    @test test_keywords_used(scatter, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), markersize = 2, color = :red, label = "new_label")
    @test test_keywords_used(scatterlines, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), marker = Circle, color = :red, label = "new_label")
    @test test_keywords_used(linesegments, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, linestyle = :dash, label = "new_label")
    @test test_keywords_used(series, dd_mat_cat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), linestyle = :dash, label = "new_label")

    @test test_keywords_used(rainclouds, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")
    @test test_keywords_used(violin, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")
    @test test_keywords_used(boxplot, dd_vec; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), color = :red, label = "new_label")

    f, a, p = lines(dd_vec; axis = (; type = LScene, show_axis = true))
    @test a isa LScene

    name = Observable(:test)
    dd = @lift DimArray(rand(X(10)), name=$name)
    fig, ax, plt = lines(dd)
    name[] = :test_2
    @test to_value(plt.label) == string(name[]) # For some reason, it updates the value but not display value in the figure. This is a Makie issue as replicable without DimArray
    @test to_value(ax.ylabel) == string(name[])
end

@testset begin

    x = 1:5
    y = 10:20
    dd_mat = DimArray( x.^1/2 .+ 0y'.^1/3, (X(x), Y(y)), name=:test)
    dd_mat_perm = DimArray( x.^1/2 .+ 0y'.^1/3, (Y(x), Ti(y)), name=:test)
    dd_mat_uni = DimArray( (x.^1/2 .+ 0y'.^1/3) .* u"Ω", (Y(x .* u"m"), Ti(y .* u"s")), name=:test)
    dd_mat_char = DimArray( x.^1/2 .+ 0y'.^1/3, (Y('a':'e'), Ti(y)), name=:test)
    dd_mat_sym = DimArray( x.^1/2 .+ 0y'.^1/3, (Y(Symbol.('a':'e')), Ti(y)), name=:test)

    for plt_i in (contour3d, surface, contour, contourf, plot)
        @test test_2d_plot(plt_i, dd_mat; x = X, y = Y)
        @test test_2d_plot(plt_i, dd_mat_perm; x = Ti, y = Y)
        @test test_2d_plot(plt_i, dd_mat_perm; x = Y, y = Ti)
        @test test_2d_plot(plt_i, dd_mat_char; x = Y, y = Ti)
        @test test_2d_plot(plt_i, dd_mat_sym; x = Y, y = Ti)

        _, _, plt = plt_i(dd_mat_perm)
        @test plt[1][] == y && plt[2][] == x # check that the permutation is correct without x and y inputs

        @test test_2d_plot(plt_i, dd_mat_uni; x = Y, y = Ti) broken = true # Limitation in Makie
    end

    @test test_2d_plot(plot, dd_mat; x = X, y = Y)

    for plt_i in (image, spy)
        @test test_2d_plot(plt_i, dd_mat; x = X, y = Y)
        @test test_2d_plot(plt_i, dd_mat_perm; x = Ti, y = Y)
        @test test_2d_plot(plt_i, dd_mat_perm; x = Y, y = Ti)
        _, _, plt = plt_i(dd_mat_perm)
        @test (plt[1][] .≈ (y[1], y[end]) .+ (-.5, .5) .* step(y)) |> all && (plt[2][] .≈ (x[1], x[end]) .+ (-.5, .5) .* step(x)) |> all # check that the permutation is correct without x and y inputs
        @test test_2d_plot(plt_i, dd_mat_uni; x = Y, y = Ti) broken = true # Limitation in Makie
    end

    @test test_2d_plot(heatmap, dd_mat; x = X, y = Y)
    @test test_2d_plot(heatmap, dd_mat_perm; x = Ti, y = Y)
    @test test_2d_plot(heatmap, dd_mat_perm; x = Y, y = Ti)
    @test test_2d_plot(heatmap, dd_mat_char; x = Y, y = Ti) broken = true # The heatmap works but the test need improvement to deal with char

    @test test_keywords_used(heatmap, dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), colormap = :inferno, label = "new_label")
    @test test_keywords_used(contourf, dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), colormap = :inferno, label = "new_label")
    @test test_keywords_used(contour, dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), colormap = :inferno, label = "new_label")
    @test test_keywords_used(spy, dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), colormap = :inferno, label = "new_label")
    @test test_keywords_used(image, dd_mat; axis = (;xlabel = "new_x", ylabel = "new_y", title = "new_title"), colormap = :inferno, label = "new_label")
    @test test_keywords_used(contour3d, dd_mat; colormap = :inferno, label = "new_label")
    @test test_keywords_used(surface, dd_mat; colormap = :inferno, label = "new_label")

    @test has_colorbar(heatmap, dd_mat)
    @test has_colorbar(spy, dd_mat)
    @test has_colorbar(contourf, dd_mat)
    @test has_colorbar(surface, dd_mat)

    @test_throws Makie.MakieCore.InvalidAttributeError surface(dd_mat; axis = (;xlabel = "new")) # Throws an error as normal makie would

    begin # Support for LScene
        f, a, p = heatmap(dd_mat; axis = (; type = LScene, show_axis = false))
        @test a isa LScene
        @test isnothing(a.scene[OldAxis])
    end

    _, _, plt = heatmap(dd_mat_perm)
    @test length(plt[1][]) == length(y)+1 && length(plt[2][]) == length(x) + 1 # check that the permutation is correct without x and y inputs
end

@testset begin

    dd_3d = DimArray(rand(5, 5, 5), (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d_char = DimArray(rand(5, 5, 5), (X('A':'E'), Y(1:5), Z(1:5)), name=:test)
    dd_3d_mis = DimArray(reshape(vcat([missing], rand(7)), 2, 2, 2), (X(1:2), Y(1:2), Z(1:2)), name=:test)
    dd_3d_uni = DimArray(rand(5, 5, 5) .* u"m", (X(1:5), Y(1:5), Z(1:5)), name=:test)
    dd_3d_rgb = DimArray(rand(RGB, 5, 5, 5), (X(1:5), Y(1:5), Z(1:5)), name=:test)

    for dd_i in (dd_3d, dd_3d_char)
        @test test_3d_plot(volume, dd_i; x = X, y = Y, z = Z)
        @test test_3d_plot(plot, dd_i; x = X, y = Y, z = Z)
        @test test_3d_plot(volumeslices, dd_i; x = X, y = Y, z = Z)
    end

    @test test_3d_plot(volume, dd_3d_mis; x = X, y = Y, z = Z)
    @test test_3d_plot(volumeslices, dd_3d_mis; x = X, y = Y, z = Z) broken = true # Limitation in CairoMakie. Works fine on GLMakie

    for dd_i in (dd_3d_uni, dd_3d_rgb) # Broken due to limitations in Makie
        @test test_3d_plot(volume, dd_i; x = X, y = Y, z = Z) broken = true 
        @test test_3d_plot(volumeslice, dd_i; x = X, y = Y, z = Z) broken = true 
    end

    @test has_colorbar(volume, dd_3d)
    @test has_colorbar(volumeslices, dd_3d)

    x = 1:5
    y = 1:6
    z = 1:7


    _, _, plt = volume(rand(Z(z), Y(y), X(x)))
    @test plt[1][][2] ≈ last(x)+1/2 && 
        plt[2][][2] ≈ last(y)+1/2 && 
        plt[3][][2] ≈ last(z)+1/2 # check that the permutation is correct without x and y inputs
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
