# Getting Started

In this tutorial, we're going to:

1. [Generate synthetic satellite data and understand its limitations as a plain array](#generate-synthetic-data)
2. [Build a `DimArray` with named dimensions and label-based indexing](#building-a-dimarray)
3. [Subset data using `At`, `Near`, `Touches`, and `Where`](#working-with-dimarrays)
4. [Combine multiple variables into a `DimStack`](#building-a-dimstack)
5. [Convert units and time coordinates using broadcasting and `set`](#step-1-temperature-conversion)
6. [Compute a monthly climatology using `groupby`](#using-groupby)
7. [Calculate temperature anomalies to identify a heatwave](#step-3-calculating-temperature-anomalies)
8. [Build a stack with layers that don't share all dimensions](#question-2-how-do-our-weather-stations-compare-to-the-global-mean)
9. [Compare station observations to the global daily mean using `@d`](#comparing-station-temperatures-to-the-global-daily-mean)

---

## Setup

First, we have to import DimensionalData and supporting packages:

````@example dimensionaldata_tutorial
using DimensionalData
using Statistics
using Random
using Dates
using CairoMakie

Random.seed!(42);
````

---

## Generate Synthetic Data

Toy data: A weather satellite records daily surface temperature and surface pressure on a 1° global grid for one year.

````@example dimensionaldata_tutorial
# 1° global grid, daily for a year.
lat  = range(-89.5, 89.5,  step = 1);
lon  = range(-179.5, 179.5, step = 1);
time = 1:365;

# Seasonal amplitude (K) as a function of latitude: tropics barely change, poles swing a lot.
season_amp(la) = 25 * (abs(la) / 90);

# Day 1 = Jan 1 (Northern Hemisphere winter).
seasonal(la, t) = season_amp(la) * sign(la) *
                  cos(2π * (t - 172) / 365);   # day 172 ≈ June 21

# Toy temperature (K): latitudinal gradient + seasonal cycle + noise.
temperature_data = [300 - 60 * abs(la / 90) + seasonal(la, t) + 3 * randn()
                    for la in lat, lo in lon, t in time];

# Inject a synthetic July heatwave over Europe (+80 K).
for (i, la) in enumerate(lat), (j, lo) in enumerate(lon),
    (k, t) in enumerate(time)
    if 40 <= la <= 55 && 0 <= lo <= 30 && 180 <= t <= 210
        temperature_data[i, j, k] += 80.0
    end
end

# Toy surface pressure (hPa): simplified coupling to temperature
baseline_temp = [300 - 60 * abs(la / 90) for la in lat, lo in lon, t in time];
temp_anom     = temperature_data .- baseline_temp;

pressure_baseline = [1013 - 10 * cosd(2 * la) for la in lat, lo in lon, t in time];
pressure_noise    = 2 .* randn(size(temperature_data));
pressure_data     = pressure_baseline .- 0.5 .* temp_anom .+ pressure_noise;
````

This creates two arrays, one for temperature and one for pressure, each with (unnamed) dimensions 180×360×365 representing latitude, longitude, and time. Each element is a lat/lon/time pair for the entire globe.

````@example dimensionaldata_tutorial
temperature_data[1:5, 1:5, 1]
````

Note that this array does not (and cannot) have names for the latitude/longitude/time axes. It lacks context that makes it impractical to easily refer to specific temperature or pressure observations at some location.

Suppose we ask: *"What was the temperature at JPL (34.2°N, 118.17°W) on day 90?"*

With a plain array, we have to translate coordinates into positional indices ourselves:

````@example dimensionaldata_tutorial
temperature_data[findfirst(==(34.5), lat), findfirst(==(-118.5), lon), 90]
````

This works, but it is cumbersome and requires us to refer to the lat/lon/time ranges generated earlier, rather than referring to metadata stored in the array object. In other words, the array does not carry its own context.

---

## Building a DimArray

Now, let's use DimensionalData to create a DimArray. A DimArray wraps the same data as our standard array, but allows us to explicitly name our dimensions, and assign lookup values to these axes. This preserves the context of our data better than a standard array.

````@example dimensionaldata_tutorial
# DimensionalData provides four default dimension types: X, Y, Z, and Ti.
temperature = DimArray(temperature_data, (Y(lat), X(lon), Ti(time)))
````

DimArray displays metadata about the dimensions, which use the default names X, Y, and Ti. It also shows the ranges for the lookups of our data, which are then displayed along our array.

In this case, they are ranges for the longitude, latitude, and time. For more context, we can create custom Dimension names:

````@example dimensionaldata_tutorial
temperature = DimArray(temperature_data, (Dim{:latitude}(lat), Dim{:longitude}(lon), Dim{:time}(time)))

# For our pressure data:
pressure = DimArray(pressure_data, (Dim{:latitude}(lat), Dim{:longitude}(lon), Dim{:time}(time)))
````

Note that our dimensions are now named `latitude`, `longitude`, and `time`, rather than the default `Y`, `X`, and `Ti`.

---

## Working with DimArrays

Now we will demonstrate some of the ways to work with DimArrays.

First, we will show standard positional indexing, compared to DimensionalData's label-based indexing.

````@example dimensionaldata_tutorial
temperature[latitude = 1] # standard positional indexing
temperature[latitude = At(-89.5)] # the same data, using label-based indexing
````

Label-based indexing simplifies the indexing process because we can use the lookups to refer to specific elements by name, rather than needing to consider the order of our data (its index positions).

Back to the question, using a DimArray: *What was the temperature at JPL (34.2°N, 118.17°W) on day 90?*

There are several Selector functions. For this problem, we would likely use either `At()` or `Near()`. `At()` requires an exact match, and errors if the coordinate we ask for is not an element in the lookup. I.e. our latitude lookup is 33.5, 34.5, 35.5... and 34.2 is not an element in that range.

`Near` finds the closest entry to the specified coordinates.

````@example dimensionaldata_tutorial
temperature[latitude = Near(34.2003), longitude = Near(-118.1711), time = At(90)]
````

Next, we want to select all temperature data from the western US on day 90.

`Touches` selects all intervals that overlap with or share a boundary with the specified range. 

````@example dimensionaldata_tutorial
west_us = temperature[latitude = Touches(32, 49), longitude = Touches(-125, -102), time = At(90)]
````

Selecting this data is analogous to making a bounding box to subset data. We will visualize this by plotting global surface temperature data, with a bounding box containing the data we selected.

````@example dimensionaldata_tutorial
field = temperature[:, :, 90]
fig = Figure()
ax  = Axis(fig[1, 1];
           title  = "Global surface temperature (day 90) - western US bounding box",
           xlabel = "Longitude", ylabel = "Latitude")
hm  = heatmap!(ax, lookup(field, :longitude), lookup(field, :latitude),
               parent(field)';
               colormap = :thermal)
# Overlay the bounding box as a rectangle:
lines!(ax, [-125, -102, -102, -125, -125], [32, 32, 49, 49, 32];
       color = :white, linewidth = 2)
Colorbar(fig[1, 2], hm; label = "Temperature (K)")
fig
````

Next, we want to create a bounding box selecting data in the tropical zone (between -23.5 and 23.5).

We use the `Where()` function which filters a dimension by passing each lookup value through a function. We pass an anonymous function that returns true when the absolute value of the latitude is less than or equal to 23.5.

````@example dimensionaldata_tutorial
tropics = temperature[latitude = Where(la -> abs(la) <= 23.5), time = At(90)]
````

````@example dimensionaldata_tutorial
fig = Figure()
field   = temperature[:, :, 90]
ax  = Axis(fig[1, 1];
           title  = "Global surface temperature (day 90) — tropics",
           xlabel = "Longitude", ylabel = "Latitude")
hm  = heatmap!(ax, lookup(field, :longitude), lookup(field, :latitude),
               parent(field)';
               colormap = :thermal)
# Overlay the tropical band boundaries at ±23.5°:
hlines!(ax, [-23.5, 23.5]; color = :white, linewidth = 2)
Colorbar(fig[1, 2], hm; label = "Temperature (K)")
fig
````

---

## Building a DimStack

DimArrays are helpful, but only store one variable (i.e. our previous DimArray only stores temperature data). However, our satellite data includes both temperature and pressure measurements. We can use a DimStack that allows us to store our pressure and temperature data within one object.

````@example dimensionaldata_tutorial
satellite_data = DimStack((temperature = temperature, pressure = pressure))
````

A DimStack is a collection of layers (DimArrays) that share some or all dimensions. In our example, temperature and pressure share all of the same dimensions, and thus share the same lookups.

Working with our data bundled in a stack means we can index or slice both layers at once.

Suppose we want to view temperature and pressure near JPL on day 90. Instead of indexing temperature and pressure individually, we can index the DimStack:

````@example dimensionaldata_tutorial
satellite_data[latitude = Near(34.2003), longitude = Near(-118.1711), time = At(90)]
````

And we can access individual layers with dot syntax:

````@example dimensionaldata_tutorial
satellite_data.pressure
````

Now we want to demonstrate DimensionalData in the context of some simple real-world questions.

---

## Question 1: Where on Earth was unusually warm in July?

To answer this question, we will need three things:

1. Convert temperature units from Kelvin to Celsius
2. Convert our time lookup from an integer range, `1:365`, to something more meaningful
3. Calculate temperature anomalies to identify a heatwave

### Step 1: Temperature Conversion

Standard broadcasting to the temperature array allows us to convert to Celsius. Note that we can directly mutate the contents of our layers within the stack. 

````@example dimensionaldata_tutorial
satellite_data.temperature .-= 273.15
````

### Step 2: Time Conversion

Now we want to convert our time dimension so that it has clear dates available to index by.

> Note: While we can mutate the *values* inside of a `DimArray`/`DimStack` layer (as we just did converting to Celsius), the *lookups* themselves are immutable (i.e. cannot be changed once the object is built). 

To change a lookup, we rebuild the object with `set` rather than assigning into it. 

````@example dimensionaldata_tutorial
# We create a new range using the Dates package.
new_time_range = range(DateTime(2024), step = Day(1), length = 365)

# We rebuild our DimStack using the set function, which reconstructs the stack and changes the lookup values to DateTime format.
satellite_data = set(satellite_data, :time => new_time_range)
````

Now we can ask for a specific year/month/day directly:

````@example dimensionaldata_tutorial
satellite_data[time = At(DateTime(2024, 7, 15))]
````

#### Using groupby

With our new time lookup, we can now demonstrate the `groupby()` function by grouping by month. For this problem, we want the average temperature for each month of the year.

````@example dimensionaldata_tutorial
# groupby lets us group along a dimension by its lookup values (the month of each date)
monthly_groups = groupby(satellite_data.temperature, :time => month)
````

The result is a DimArray of DimArrays, one array per month. Note that the days in each month reflect the month's actual length.

**Side note on `groupby`:** We can group by other metrics, such as the day of the week:

````@example dimensionaldata_tutorial
day_of_week_groups = groupby(satellite_data.temperature, :time => dayofweek)
````

Or grouping by seasons, where we use the `Bins` function. The `Bins` function maps each lookup value into a named group based on the bin it falls into.

````@example dimensionaldata_tutorial
# Group by seasons DJF, MAM, JJA, SON:
season_groups = groupby(satellite_data.temperature, :time => Bins(month, [[12, 1, 2], 3:5, 6:8, 9:11]))
````

Here, the `month` function is applied to each time value, extracting the month number. Then, it bins the months into 4 custom bins, each with 3 months, representing seasons.

We now have grouped our data by month, by day of the week, and by seasons. Going forward, we will use the monthly grouping.

### Step 3: Calculating temperature anomalies

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
anomalies = satellite_data.temperature .- climatology_daily
````

We now have a DimArray where every lat/lon/day pair is a temperature anomaly, to show us how much the temperature at each day deviates from its respective month's mean temperature. We will visualize one day of temperature anomaly to inspect what we just did.

````@example dimensionaldata_tutorial
july_day = anomalies[time = At(DateTime(2024, 7, 15))]
# We choose July 15th "arbitrarily" (the toy data has a heatwave added in the summer).

fig, ax, hm = heatmap(lookup(july_day, :longitude), lookup(july_day, :latitude), parent(july_day)';
                      colormap = :balance, colorrange = (-15, 15),
                      axis = (title = "Temperature anomaly, 2024-07-15 (°C)", xlabel = "Longitude", ylabel = "Latitude"))
Colorbar(fig[1, 2], hm)
fig
````

---

## Question 2: How do our weather stations compare to the global mean?

Now we want to demonstrate working with DimStacks whose layers have some different dimensions. Remember that the layers in a stack must share some or all dimensions.

````@example dimensionaldata_tutorial
# Data generation:
station_names = ["JPL", "Mauna Loa", "McMurdo", "Zurich", "Quito"]
station_lats  = [ 34.543,    19.273,      -77.412,     47.670,     -0.432  ]
station_lons  = [-118.772,  -155.651,     166.501,      8.494,    -78.514  ]
station_bias  = [  0.5,    -0.3,       1.2,      -0.8,      0.1  ]

station_matrix = zeros(length(station_names), length(new_time_range))
for (i, (la, lo, b)) in enumerate(zip(station_lats, station_lons, station_bias))
    series = satellite_data.temperature[latitude = Near(la), longitude = Near(lo)]
    station_matrix[i, :] = parent(series) .+ b .+ 0.5 .* randn(365)
end

station_obs = DimArray(station_matrix, (Dim{:station}(station_names), Dim{:time}(new_time_range)))
````

Our five stations' coordinates do not fall on the satellite grid's 1-degree cells, meaning we cannot align them using latitude and longitude as shared dimensions. However, both datasets share an identical time lookup, meaning we can combine them in a stack. 

`station_obs` lives on `(station, time)` while the satellite layers live on `(latitude, longitude, time)`.

````@example dimensionaldata_tutorial
combined = DimStack((
    temperature = satellite_data.temperature,
    pressure    = satellite_data.pressure,
    station_obs = station_obs
))
````

The output confirms that station_obs shares the time dimension with the satellite layers while living on its own station dimension, no latitude or longitude needed. 

> Note: Shared dimensions must share *identical* lookups. Layers in a `DimStack` can live on some different dimensions, but wherever they *do* share a dimension, the lookups must match exactly. Our combined stack assembles only because `station_obs` was built from the same `new_time_range` as the satellite layers, so their `time` lookups are identical. 

Fortunately, our stations record one observation per day. If they made one measurement per hour, while our satellite data takes daily measurements, we would need another solution, as the lookup ranges would not match. 

### Comparing station temperatures to the global daily mean

Now we want to compare station temperature to the global daily temperature.

````@example dimensionaldata_tutorial
# First we calculate global daily mean:
global_daily_mean = mean(satellite_data.temperature, dims = (:latitude, :longitude))

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
field     = satellite_data.temperature[time = At(plot_date)]
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