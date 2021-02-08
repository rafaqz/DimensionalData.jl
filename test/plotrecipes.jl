using DimensionalData, Test, Plots, Dates, StatsPlots

import Distributions

A1 = rand(Distributions.Normal(), 20)
ref = (Ti(1, Sampled(Ordered(), Regular(Day(1)), Points())),)
da1_regular = DimArray(A1, X(1:50:1000), :Normal; refdims=ref)
da1_noindex = DimArray(A1, X(), :Normal; refdims=ref)
da1_categorical = DimArray(A1, X('A':'T'), :Normal; refdims=ref)
da1_z = DimArray(A1, Z(1:50:1000), :Normal; refdims=ref)

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
        marginalhist(da1)
        ea_histogram(da1)
        density(da1)
    end
end

A2 = rand(Distributions.Normal(), 40, 20)
da2_regular = DimArray(A2, (X(1:10:400), Y(1:5:100)), :Normal)
da2_noindex = DimArray(A2, (X(), Y()), :Normal)
da2_ni_r = DimArray(A2, (X(), Y(1:5:100)), :Normal)
da2_r_ni = DimArray(A2, (X(1:10:400), Y()), :Normal)
da2_c_c = DimArray(A2, (X('A':'h'), Y('a':'t')), :Normal)
da2_XY = DimArray(A2, (X(1:10:400), Y(1:5:100)), :Normal)
da2_YX = DimArray(A2, (Y(1:10:400), X(1:5:100)), :Normal)
da2_ZY = DimArray(A2, (Z(1:10:400), Y(1:5:100)), :Normal)

# For manual testing
da2 = da2_XY

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
