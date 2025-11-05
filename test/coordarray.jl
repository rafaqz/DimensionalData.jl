using DimensionalData, Test, Dates
using DimensionalData: coords
using DimensionalData: At, Between, Near, NoName, NoMetadata, format, checkdims

@testset "CoordArray" begin

    @testset "CoordArray construction" begin
        # Test the new (dimensions, data) syntax
        data = rand(3, 4, 5)
        lat = rand(3, 4)
        lon = rand(3, 4)
        elevation = rand(5)

        xdim = X(1:3)
        ydim = Y(1:4)
        zdim = Z(1:5)
        coords1 = (;
            latitude=((X, Y), lat),
            longitude=((X, Y), lon),
            elevation=((Z,), elevation)
        )
        coords2 = (;
            latitude=DimArray(lat, (xdim, ydim)),
            longitude=DimArray(lon, (xdim, ydim)),
            elevation=DimArray(elevation, zdim)
        )

        for coordspec in (coords1, coords2)
            DimArray(data, (xdim, ydim, zdim))
            da = CoordArray(data, (xdim, ydim, zdim); coords=coordspec, name="temperature")

            @test coords(da).latitude isa DimArray
            @test coords(da).longitude isa DimArray
            @test coords(da).elevation isa DimArray
            @test coords(da).latitude.dims == da.dims[1:2]
            @test coords(da).longitude.dims == da.dims[1:2]
            @test coords(da).elevation.dims == (zdim,)
        end

    end

    @testset "CoordArray indexing" begin
        temperature = 15 .+ 8 .* randn(2, 3, 4)
        lon = [[42.25 42.21 42.63]; [42.63 42.59 42.59]]# 2x3 matrix
        lat = [[-99.83 -99.32]; [-99.79 -99.23]; [-99.79 -99.23]]  # 3x2 matrix     
        time_vals = DateTime(2014, 9, 6):Day(1):DateTime(2014, 9, 9)
        reference_time = DateTime(2014, 9, 5)

        x_dim = X(1:2)
        y_dim = Y(1:3)
        time_dim = Ti(time_vals)

        lon = DimArray(lon, (x_dim, y_dim))
        lat = DimArray(lat, (y_dim, x_dim))

        # Create CoordArray with non-dimension coordinates
        da = CoordArray(
            temperature,
            (x_dim, y_dim, time_dim);
            coords=(; lon, lat, reference_time),
        )

        # Test coordinate access
        @test haskey(coords(da), :lon)
        @test haskey(coords(da), :lat)
        @test haskey(coords(da), :reference_time)

        # Test indexing with coordinates
        @test da[Ti(At(time_vals[3])), X(2), Y(:)] == temperature[2, :, 3]
        new_da = da[Ti(At(time_vals[2])), X(2), Y(:)]
        @test new_da.coords.lon == lon[2, :]
        @test new_da.coords.lat == lat[:, 2]
        @test new_da.coords.reference_time == reference_time
    end
end