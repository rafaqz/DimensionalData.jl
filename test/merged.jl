using DimensionalData, Test, Unitful, Extents
using DimensionalData.Lookups, DimensionalData.Dimensions
using Statistics: mean
using DimensionalData.Dimensions: SelOrStandard

dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
da = DimArray(0.1:0.1:0.4, dim)
da2 = DimArray((0.1:0.1:0.4) * (1:1:3)', (dim, Ti(1u"s":1u"s":3u"s")); metadata=Dict())

@testset "regular indexing" begin
    @test da[Coord()] == da[Coord(:)] == da
    @test da[Coord([1, 2])] == [0.1, 0.2]
    @test da[Coord(4)] == 0.4
    @test da2[Coord(4), Ti(3)] ≈ 1.2
end

@testset "subdim indexing" begin
    @test da[X(At(1))] == da[Coord(X(At(1)))]
    @test da[X(At(1)), Y(At(1))] == da[Coord(X(At(1)), Y(At(1)))]
    @test da[X(At(1)), Y(At(1)), Z(At(1))] == da[Coord(X(At(1)), Y(At(1)), Z(At(1)))]
    @test da[Y(At(1)), Z(At(1))] == da[Coord(Y(At(1)), Z(At(1)))]
    @test da[Z(At(4))] == da[Coord(Z(At(4)))]
end

@testset "merged selector indexing" begin
    @test da[Coord(:, :, :)] == [0.1, 0.2, 0.3, 0.4]
    @test da[Coord(Between(1, 5), :, At(4.0))] == [0.3, 0.4]
    @test da[Coord(:, Between(1, 2), :)] == [0.1, 0.2]
    @test da2[Ti(At(1u"s")), Coord(:, Between(1, 2), :)] == [0.1, 0.2]
    @test da2[Ti(At(2u"s")), Coord(:, Where(>=(3)), :)] == [0.6, 0.8]
    @test_throws ArgumentError da[var=1, Coord(:, Near(1), :)] 
end

@testset "merged dimension indexing" begin
    @test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == [0.1]
    @test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == da[Z(At(1.0)), Y(Between(1, 3))]
end

@test index(da[Coord(:, Between(1, 2), :)], Coord) == [(1.0,1.0,1.0), (1.0,2.0,2.0)]

@test DimensionalData.bounds(da) == (((1.0, 3.0), (1.0, 4.0), (1.0, 4.0)),)

@testset "merged named reduction" begin
    m = mean(da2; dims=Coord)
    @test size(m) == (1,3)
    @test length(dims(m, Coord)) == 1
    @test dims(m, Coord).val == DimensionalData.NoLookup(Base.OneTo(1))
    pure_mean = mean(da2.data; dims = 1)
    @test vec(pure_mean) == vec(m.data)
end

@testset "merged indexing with intervals" begin
    @test da[Coord(Z(At(1.0)), Y(1..3))] == [0.1]
    @test da[Z(At(1.0)), Y(1..3)] == [0.1]
    @test da2[Ti(At(1u"s")), Coord(X(At(1.0)), Y(At(3.0)), Z(At(4.0)))] == 0.4
    @test da2[Ti(At(1u"s")), X(At(1.0)), Y(1..3)] == [0.1, 0.2, 0.4]
end

@testset "custom merged names" begin
    A = (1:2) * (1:40)'
    merged = Dim{:mymerged}(Dimensions.MergedLookup(map(Tuple, vec(CartesianIndices((1:10, 1:4)))), (Dim{:draw}(), Dim{:chain}())))
    da = DimArray(A, (Dim{:var}(1:2), merged))
    @test da[var=2, mymerged=(Dim{:draw}(At(8)), Dim{:chain}(At(4)))] == 76
    @test da[var=1, mymerged=(draw=At(8), chain=At(1))] == 8 
    @test da[var=1, draw=At(8), chain=At(1)] == 8 
end

@testset "show merged" begin
    sprint(show, dim)
    sp = sprint(show, MIME"text/plain"(), dim)
    @test occursin("Coord", sp)
    sp = sprint(show, MIME"text/plain"(), da)
    @test occursin("Coord", sp)
    @test occursin("X", sp)
    @test occursin("Y", sp)
    @test occursin("Z", sp)
end

@testset "unmerge" begin
    a = DimArray(rand(32, 32, 3), (X,Y,Dim{:band}))
    b = DimStack((;a))
    for a in (a, b)
        merged = mergedims(a, (X, Y) => :geometry)
        unmerged = unmergedims(merged, dims(a))
        perm_unmerged = unmergedims(permutedims(merged, (2,1)), dims(a))
        
        # Test Merge
        @test hasdim(merged, Dim{:band})
        @test hasdim(merged, Dim{:geometry})
        @test !hasdim(merged, X)
        @test !hasdim(merged, Y)
        @test size(merged) == (3, 32 * 32)

        # Test Unmerge
        @test hasdim(unmerged, X)
        @test hasdim(unmerged, Y)
        @test hasdim(unmerged, Dim{:band})
        @test !hasdim(unmerged, Dim{:geometry})
        @test dims(unmerged) == dims(a)
        @test size(unmerged) == size(a)
        @test all(a .== unmerged)
        @test all(a .== perm_unmerged)
    end
end

@testset "indexing with totally random dim on merged lookup still errors" begin
    da = ones(X(1:10), Y(1:10), Dim{:random}(1:10))
    merged = mergedims(da, (X, Y) => :space)
    @test_warn "Z" merged[Z(1)]
end

@testset "hasmultipledimensions trait for PR #991" begin
    # Test default behavior for regular lookups
    @testset "Regular lookups return false" begin
        @test hasmultipledimensions(NoLookup()) == false
        @test hasmultipledimensions(Sampled(1:10)) == false
        @test hasmultipledimensions(Categorical([:a, :b, :c])) == false
        @test hasmultipledimensions(Cyclic(1:12; cycle=12)) == false
        @test hasmultipledimensions(Sampled(1:10; sampling=Points())) == false
        @test hasmultipledimensions(Sampled(1:10; sampling=Intervals())) == false
    end

    @testset "MergedLookup returns true" begin
        x_dim = X(1:3)
        y_dim = Y(10:10:30)
        merged_data = vec(DimPoints((x_dim, y_dim)))
        merged_lookup = Dimensions.MergedLookup(merged_data, (x_dim, y_dim))
        @test hasmultipledimensions(merged_lookup) == true
    end

    @testset "Extent passthrough for MergedLookup" begin
        # Basic extent with MergedLookup
        x_vals = 1.0:3.0
        y_vals = 10.0:10.0:30.0
        x_dim = X(x_vals)
        y_dim = Y(y_vals)
        
        merged_dims = mergedims((x_dim, y_dim) => :space)
        ext = Extents.extent((merged_dims,))
        
        @test haskey(ext, :X)
        @test haskey(ext, :Y)
        @test ext.X == (1.0, 3.0)
        @test ext.Y == (10.0, 30.0)

        # Mixed regular and merged dimensions
        t_dim = Ti(1:5)
        z_dim = Z(100:100:300)
        all_dims = (t_dim, merged_dims, z_dim)
        ext2 = Extents.extent(all_dims)
        
        @test ext2.Ti == (1, 5)
        @test ext2.Z == (100, 300)
        @test ext2.X == (1.0, 3.0)
        @test ext2.Y == (10.0, 30.0)
    end

    @testset "Multiple merged dimensions extent" begin
        x1_dim = X(1:3)
        y1_dim = Y(10:10:30)
        t_dim = Ti(0.0:0.5:1.0)
        z_dim = Z(-5:5)
        
        merged_space = mergedims((x1_dim, y1_dim) => :space)
        merged_tz = mergedims((t_dim, z_dim) => :timez)
        all_dims = (merged_space, merged_tz)
        
        ext = Extents.extent(all_dims)
        @test ext.X == (1, 3)
        @test ext.Y == (10, 30)
        @test ext.Ti == (0.0, 1.0)
        @test ext.Z == (-5, 5)
    end

    @testset "Extent with subset of dimensions" begin
        x_dim = X(1:5)
        y_dim = Y(10:10:50)
        z_dim = Z(100:100:300)
        
        merged = mergedims((x_dim, y_dim) => :space)
        all_dims = (merged, z_dim)
        
        # Get extent for just the Z dimension
        ext_z = Extents.extent(all_dims, Z)
        @test ext_z.Z == (100, 300)
        @test !haskey(ext_z, :X)
        @test !haskey(ext_z, :Y)
        
        # Get extent for merged dimension by name
        ext_space = Extents.extent(all_dims, :space)
        @test ext_space.X == (1, 5)
        @test ext_space.Y == (10, 50)
        @test !haskey(ext_space, :Z)
    end

    @testset "Operations preserve hasmultipledimensions" begin
        x = X(1:3)
        y = Y(10:10:30)
        data = rand(3, 3)
        
        da = DimArray(data, (x, y))
        merged_da = mergedims(da, (X, Y) => :space)
        
        # Broadcasting preserves trait
        result = merged_da .+ 1
        @test hasmultipledimensions(lookup(dims(result, :space)))
        
        # Slicing with additional dimension preserves trait
        z = Z(1:3)
        data3d = rand(3, 3, 3)
        da3d = DimArray(data3d, (x, y, z))
        merged_da3d = mergedims(da3d, (X, Y) => :space)
        sliced = merged_da3d[Z(At(2))]
        @test hasmultipledimensions(lookup(dims(sliced, :space)))
    end
end