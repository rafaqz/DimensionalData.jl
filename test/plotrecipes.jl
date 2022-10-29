using DimensionalData, Test, Plots, Dates, StatsPlots, Unitful
import Distributions

using DimensionalData: Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered,
    Sampled, Categorical, NoLookup, Transformed,
    Regular, Irregular, Explicit, Points, Intervals, Start, Center, End

A1 = rand(Distributions.Normal(), 20)
ref = (Ti(Sampled(1:1; order=ForwardOrdered(), span=Regular(Day(1)), sampling=Points())),)
da1_regular = DimArray(A1, X(1:50:1000); name=:Normal, refdims=ref)
da1_noindex = DimArray(A1, X(); name=:Normal, refdims=ref)
da1_categorical = DimArray(A1, X('A':'T'); name=:Normal, refdims=ref)
da1_z = DimArray(A1, Z(1:50:1000); name=:Normal, refdims=ref)

# For manual testing
da1 = da1_z

for da in (da1_regular, da1_noindex, da1_categorical, da1_z)
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

nothing

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
