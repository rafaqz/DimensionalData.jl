# Getting Started

In this tutorial, we're going to:

1. [Create synthetic data](#create-synthetic-data)
2. [Build a `DimArray` with named dimensions and lookup-based indexing](#build-a-dimarray-with-named-dimensions-and-lookup-based-indexing)
3. [Subset data using `At`, `Near`, `Touches`, and `Where`](#subset-data-using-at-near-touches-and-where)
4. [Combine multiple variables into a `DimStack`](#combine-multiple-variables-into-a-dimstack)
5. [Rebuild a DimStack using `set` to update metadata](#rebuild-a-dimstack-using-set-to-update-metadata)
6. [Compute climatology using `groupby`](#compute-climatology-using-groupby)
7. [Compute statistics using `map`](#compute-statistics-using-map)
8. [Build a DimStack of DimArrays with differing shared dimensions](#build-a-dimstack-of-dimarrays-with-differing-shared-dimensions)
9. [Dimension-aware operations using `@d`](#dimension-aware-operations-using-d)

---

## Setup

First, we have to import DimensionalData and supporting packages:

````julia
using Pkg
Pkg.add(["DimensionalData", "Statistics", "Random", "Dates", "CairoMakie"])
````

````@example dimensionaldata_tutorial
using DimensionalData
using Statistics
using Random
using Dates
using CairoMakie

Random.seed!(42)
````

---

## Create Synthetic Data

Synthetic data: One year of daily surface temperature and pressure on a 1° by 1° global grid.

````@example dimensionaldata_tutorial
# 1° global grid, daily for a year.
lats = -89.5:89.5
lons = -179.5:179.5
times = 1:365

# Seasonal amplitude (K) as a function of latitude: low seasonal variability near equator, high seasonal variability near poles.
season_amp(lat) = 25 * (abs(lat) / 90)

# Day 1 = Jan 1 (Northern Hemisphere winter).
seasonal(lat, t) = season_amp(lat) * sign(lat) *
                  cos(2π * (t - 172) / 365)   # day 172 ≈ June 21

# Synthetic temperature (K): latitudinal gradient + seasonal cycle + noise.
temperature_data = [27 - 60 * abs(lat / 90) + seasonal(lat, t) + 3 * randn()
                    for lat in lats, lon in lons, t in times]

# Inject a synthetic July heatwave over Europe (+30 C).
for (i, lat) in enumerate(lats), (j, lon) in enumerate(lons),
    (k, t) in enumerate(times)
    if 40 <= lat <= 55 && 0 <= lon <= 30 && 180 <= t <= 210
        temperature_data[i, j, k] += 30.0
    end
end

# Synthetic surface pressure (hPa): simplified coupling to temperature
baseline_temp = [27 - 60 * abs(lat / 90) for lat in lats, lon in lons, t in times]
temp_anom     = temperature_data .- baseline_temp

pressure_baseline = [1013 - 10 * cosd(2 * lat) for lat in lats, lon in lons, t in times]
pressure_noise    = 2 .* randn(size(temperature_data))
pressure_data     = pressure_baseline .- 0.5 .* temp_anom .+ pressure_noise;
````

The above code creates two 3D Arrays, one for temperature and one for pressure, each with dimensions 180×360×365 representing latitude, longitude, and time.

````@example dimensionaldata_tutorial
temperature_data[1:5, 1:5, 1]
````

Suppose we ask: *"What was the temperature in Los Angeles (34.2°N, 118.17°W) on day 90?"*

With a plain array, we have to translate dimensional coordinates into positional indices ourselves:

````@example dimensionaldata_tutorial
i =  findfirst(==(34.5), lats)  
j = findfirst(==(-118.5), lons)  
k = 90  
temperature_data[i,j,k] 
````

Translating between dimension coordinates and array indices is a common operation when working with dimensional data. Such translations are onerous and can be difficult to track as the complexity of the code increases. DimensionalData provides a high level abstraction for working with such data.

---

## Building a DimArray

Now, let's use DimensionalData to create a DimArray. A DimArray allows one to assign names and lookup values to the axes of an Array. This facilitates intuitive and persistent mapping between dimension coordinates and array values.

````@example dimensionaldata_tutorial
# DimensionalData provides four predefined dimension types: X, Y, Z, and Ti.
y = Y(lats)
x = X(lons)
ti = Ti(times)

temperature = DimArray(temperature_data, (y,x,ti))
````

DimArray displays metadata about the dimensions, with four predefined types: X, Y, and Ti. It also shows the ranges for the lookups of our data, which are then displayed along our array.

In this case, they are ranges for the longitude, latitude, and time. For more context, we can create custom Dimension names:

````@example dimensionaldata_tutorial
latitude = Dim{:latitude}(lats)
longitude = Dim{:longitude}(lons)
time = Dim{:time}(times)

temperature = DimArray(temperature_data, (latitude, longitude, time))

# For our pressure data:
pressure = DimArray(pressure_data, (latitude, longitude, time))
````

Note that our dimensions are now named `latitude`, `longitude`, and `time`, rather than the predefined `Y`, `X`, and `Ti`.

`Dim{:name}` is generally the simplest way to attach a custom name to an axis. We can also create custom dimensions using the `@dim` macro, which lets our named dimension inherit from an abstract supertype like `XDim` or `YDim` so methods that dispatch on axis type (e.g. plotting) accommodate our custom dimension directly. In other words, this allows us to directly relate a custom dimension like `Lat` to `YDim`, so `Lat` will be treated as the y-axis of our data. 

````@example dimensionaldata_tutorial
using DimensionalData: @dim, YDim, XDim

@dim Lat YDim "latitude"
@dim Lon XDim "longitude"
temperature_latlon = DimArray(temperature_data, (Lat(lats), Lon(lons), Ti(times)))
````

However, it is generally not necessary to use this macro manually, as IO packages handle dimension types when reading in data.

---

## Subset data using `At`, `Near`, `Touches`, and `Where`

Now we will demonstrate some of the ways to work with DimArrays.

First, we will show standard positional indexing, compared to DimensionalData's lookup-based indexing.

````@example dimensionaldata_tutorial
temperature[1, :, :] # standard positional indexing
````

````@example dimensionaldata_tutorial
temperature[latitude = At(-89.5)] # the same data, using lookup-based indexing
````

Lookup-based indexing simplifies the indexing process because we can use the lookups to refer to specific elements by name, rather than needing to consider the order of our data (its index positions).

Back to the question, using a DimArray: *What was the temperature in Los Angeles (34.2°N, 118.17°W) on day 90?*

There are several Selector functions. For this problem, we would likely use either `At()` or `Near()`. `At()` requires an exact match, and errors if the coordinate we ask for is not an element in the lookup. I.e. our latitude lookup is -89.5:89.5.. so 34.5 is an element in the lookup range while 34.2 is not.

`Near` finds the closest entry to the specified coordinates.

````@example dimensionaldata_tutorial
temperature[latitude = Near(34.2), longitude = Near(-118.2), time = At(90)]
````

Next, we want to select all temperature data from the western US on day 90.

`Touches` selects all intervals that overlap with or share a boundary with the specified range. 

````@example dimensionaldata_tutorial
west_us = temperature[latitude = Touches(32, 49), longitude = Touches(-125, -102), time = At(90)]
````

We can then visualize the selected region by plotting a surface temperature heatmap for day 90.

````@example dimensionaldata_tutorial
heatmap(west_us'; colormap = :thermal, axis = (title = "Surface temperature (day 90) - Western US",))
````

Next, we want to create a bounding box selecting data in the tropical zone (between -23.5 and 23.5).

We use the `Where()` function which filters a dimension by passing each lookup value through a function. We pass an anonymous function that returns true when the absolute value of the latitude is less than or equal to 23.5.

````@example dimensionaldata_tutorial
tropics = temperature[latitude = Where(lat -> abs(lat) <= 23.5), time = At(90)]
````

````@example dimensionaldata_tutorial
heatmap(tropics'; colormap = :thermal, axis = (title = "Surface temperature (day 90) - tropics",))
````

---

## Combine multiple variables into a `DimStack`

DimArrays are helpful, but only store one variable (i.e. our previous DimArray only stores temperature data). However, our data includes both temperature and pressure measurements. We can use a DimStack that allows us to store our pressure and temperature data within one object.

````@example dimensionaldata_tutorial
climate = DimStack((temperature = temperature, pressure = pressure))
````

A DimStack is a collection of layers (DimArrays) that may share some or all dimensions. Where two layers do share a dimension, that dimension must have the identical lookup. In our example, temperature and pressure share all of the same dimensions, and thus share the same lookups.

Working with our data bundled in a stack means we can index or slice both layers at once.

Suppose we want to view temperature and pressure in Los Angeles on day 90. Instead of indexing temperature and pressure individually, we can index the DimStack:

````@example dimensionaldata_tutorial
climate[latitude = Near(34.2), longitude = Near(-118.2), time = At(90)]
````

And we can access individual layers with dot syntax or using a Symbol:

````@example dimensionaldata_tutorial
climate.pressure # dot syntax
climate[:pressure] # Symbol
````

Now we want to demonstrate DimensionalData in the context of some simple real-world questions.

---

## Question 1: Where on Earth was unusually warm in July?

To answer this question, we will need a few things:

1. Convert our time lookup from an integer range, `1:365`, to something more meaningful
2. Group our data by month
3. Calculate temperature anomalies to identify a heatwave

## Rebuild a DimStack using `set` to update metadata

We want to convert our time dimension from integer days since December 31, 2013 to a human readable date format.

> Note: While we can mutate the *values* inside of a `DimArray`/`DimStack` layer (such as broadcasting to convert the units of temperature), the *lookups* themselves are immutable (i.e. cannot be changed once the object is built). 

To change a lookup, we rebuild the object with `set` rather than assigning into it. 

````@example dimensionaldata_tutorial
# We create a new range using the Dates package.
new_time_range = range(DateTime(2024), step = Day(1), length = 365)

# We rebuild our DimStack using the set function, which reconstructs the stack and changes the lookup values to DateTime format.
climate = set(climate, :time => new_time_range)
````

Now we can ask for a specific year/month/day directly:

````@example dimensionaldata_tutorial
climate[time = At(DateTime(2024, 7, 15))]
````

## Compute climatology using `groupby`

With our new time lookup, we can now demonstrate the `groupby()` function by grouping by month. For this problem, we want the average temperature for each month of the year.

````@example dimensionaldata_tutorial
# groupby lets us group along a dimension by its lookup values (the month of each date)
monthly_groups = groupby(climate.temperature, :time => month)
````

The result is a DimArray of DimArrays, one array per month. Note that the days in each month reflect the month's actual length.

**Side note on `groupby`:** We can group by other metrics, such as the day of the week:

````@example dimensionaldata_tutorial
day_of_week_groups = groupby(climate.temperature, :time => dayofweek)
````

Or grouping by seasons, where we use the `Bins` function. The `Bins` function maps each lookup value into a named group based on the bin it falls into.

````@example dimensionaldata_tutorial
# Group by seasons DJF, MAM, JJA, SON:
season_groups = groupby(climate.temperature, :time => Bins(month, [[12, 1, 2], 3:5, 6:8, 9:11]))
````

Here, the `month` function is applied to each time value, extracting the month number. Then, it bins the months into 4 custom bins, each with 3 months, representing seasons.

We now have grouped our data by month, by day of the week, and by seasons. Going forward, we will use the monthly grouping.

## Compute statistics using `map`

We compute the monthly mean temperature for each lat/lon point by using `map` to apply the mean over the time dimension of each monthly group, then concatenate the results into a single 180×360×12 array.

````@example dimensionaldata_tutorial
monthly_climatology = map(g -> dropdims(mean(g; dims = :time); dims = :time), monthly_groups)
# Mean over time within each monthly group, dropping the singleton time dim 
# creates one 180×360 array per month

monthly_climatology = cat(monthly_climatology...; dims = Dim{:month}(1:12))
# Concatenate the twelve arrays along a new dimension named month, with lookup 1:12
````

The next step is to calculate anomalies - the difference between each day's observed temperature and the mean temperature for that month.

To subtract `monthly_climatology` from the daily data, the two arrays need matching dimensions. One is 180×360×**12** and the other is 180×360×**365**. We close the gap in two steps: first we expand `monthly_climatology` into a 180×360×365 array, then we relabel its `month` dimension as `time` so the axes align.


````@example dimensionaldata_tutorial
# Step 1
climatology_daily = monthly_climatology[month = At(month.(new_time_range))]
# month.(new_time_range) gives the month number for all 365 days
# At(...) repeats each monthly mean across that month's days, expanding the array to 180×360×365

# Step 2
climatology_daily = set(climatology_daily, :month => Dim{:time}(new_time_range))
# The new axis is still named month, so relabel it time with the matching DateTime lookup

# Axes now align and the subtraction is a plain broadcast:
anomalies = climate.temperature .- climatology_daily
````

We now have a DimArray where every lat/lon/day pair is a temperature anomaly, to show us how much the temperature at each day deviates from its respective month's mean temperature. We will visualize one day of temperature anomaly to inspect what we just did.

````@example dimensionaldata_tutorial
july_day = anomalies[time = At(DateTime(2024, 7, 15))]
# We choose July 15th "arbitrarily" (the toy data has a heatwave added in the summer).

heatmap(july_day'; colormap = :balance, colorrange = (-15, 15),
        axis = (title = "Temperature anomaly, 2024-07-15 (°C)",))
````

---

TODO: Rework question 2
## Question 2: How do weather stations compare to the global mean?

Now we want to demonstrate working with DimStacks whose layers have some different dimensions. We generate data from weather stations whose coordinates do not align on the 

````@example dimensionaldata_tutorial
# Data generation:
station_names = ["JPL", "Mauna Loa", "McMurdo", "Zurich", "Quito"]
station_lats  = [ 34.543,    19.273,      -77.412,     47.670,     -0.432  ]
station_lons  = [-118.772,  -155.651,     166.501,      8.494,    -78.514  ]
station_bias  = [  0.5,    -0.3,       1.2,      -0.8,      0.1  ]

station_matrix = zeros(length(station_names), length(new_time_range))
for (i, (lat, lon, b)) in enumerate(zip(station_lats, station_lons, station_bias))
    series = climate.temperature[latitude = Near(lat), longitude = Near(lon)]
    station_matrix[i, :] = parent(series) .+ b .+ 0.5 .* randn(365)
end

station_obs = DimArray(station_matrix, (Dim{:station}(station_names), Dim{:time}(new_time_range)))
````

## Build a DimStack of DimArrays with differing shared dimensions

Our five stations' coordinates do not fall on the satellite grid's 1-degree cells, meaning we cannot align them using latitude and longitude as shared dimensions. However, both datasets share an identical time lookup, meaning we can combine them in a stack. 

`station_obs` lives on `(station, time)` while the satellite layers live on `(latitude, longitude, time)`.

````@example dimensionaldata_tutorial
combined = DimStack((
    temperature = climate.temperature,
    pressure    = climate.pressure,
    station_obs = station_obs
))
````

The output confirms that station_obs shares the time dimension with the satellite layers while living on its own station dimension, no latitude or longitude needed. 

> Note: Shared dimensions must share *identical* lookups. Layers in a `DimStack` can live on some different dimensions, but wherever they *do* share a dimension, the lookups must match exactly. Our combined stack assembles only because `station_obs` was built from the same `new_time_range` as the satellite layers, so their `time` lookups are identical. 

Fortunately, our stations record one observation per day. If they made one measurement per hour, while our satellite data takes daily measurements, we would need another solution, as the lookup ranges would not match. 

### Dimension-aware operations using `@d`

Now we want to compare station temperature to the global daily mean temperature.

````@example dimensionaldata_tutorial
# First we calculate global daily mean:
global_daily_mean = mean(climate.temperature, dims = (:latitude, :longitude))

# Drop the latitude and longitude dimensions
global_daily_mean = dropdims(global_daily_mean, dims = (:latitude, :longitude))
````

Our first instinct might be to subtract using standard broadcasting:

```julia
combined.station_obs .- global_daily_mean
```

But this errors: 

```julia
ERROR: DimensionMismatch: arrays could not be broadcast to a common size:
a has axes Dim{:station}(Base.OneTo(5)) and b has axes Dim{:time}(Base.OneTo(365))
```

Recall that `station_obs` is a 5×365 array containing daily temperature data per station, and `global_daily_mean` is a 365-element DimArray. Standard Julia aligns dimensions by position, so it matches the first axis of `station_obs` (station, length 5) against the only axis of `global_daily_mean` (time, length 365), resulting in an error.

We want alignment based on the time dimension.

The DimensionalData macro `@d` broadcasts by matching shared dimension names rather than position. Since both arrays share `time`, it aligns on that dimension.

````@example dimensionaldata_tutorial
station_vs_global = @d combined.station_obs .- global_daily_mean
````

````@example dimensionaldata_tutorial
fig = Figure(size = (900, 400))
ax = Axis(fig[1, 1];
          title  = "Station departure from daily global mean",
          xlabel = "Date", ylabel = "Temperature departure (°C)")
for name in station_names
    lines!(ax, new_time_range, parent(station_vs_global[station = At(name)]);
           label = name)
end
axislegend(ax; position = :rb)
fig
````

To tie together the gridded satellite data and the point-based station observations, we can visualize both on the same map:

````@example dimensionaldata_tutorial
plot_date = DateTime(2024, 7, 15)
field     = climate.temperature[time = At(plot_date)]
obs_today = station_obs[time = At(plot_date)]

fig = Figure()
ax  = Axis(fig[1, 1];
           title  = "Surface temperature on $(Date(plot_date)) (°C)",
           xlabel = "Longitude", ylabel = "Latitude")
hm  = heatmap!(ax, lookup(field, :longitude),
                   lookup(field, :latitude),
                   parent(field)';
               colormap   = :thermal,
               colorrange = (-40, 35))
scatter!(ax, station_lons, station_lats;
         color       = parent(obs_today),
         colormap    = :thermal,
         colorrange  = (-40, 35),
         strokecolor = :white, strokewidth = 2,
         markersize  = 18)
Colorbar(fig[1, 2], hm; label = "Temperature (°C)")
fig
````

Working through this toy dataset, you've seen how DimensionalData turns a plain array into an intuitive object that carries its own context. We organized data into `DimArray`s and `DimStack`s with named dimensions and meaningful lookups; subset it by label with `At`, `Near`, `Touches`, and `Where` instead of integer indices; reshaped immutable objects with `set`; summarized along a dimension with `groupby`; and used the `@d` macro to broadcast across arrays that share only some of their dimensions. We used these to help us answer real questions: where it was unusually warm, and how weather stations compare to a global average. For the full API, see the DimensionalData [documentation](https://rafaqz.github.io/DimensionalData.jl/stable/).