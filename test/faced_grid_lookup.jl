# test/faced_grid_lookup.jl
using DimensionalData, Test
using DimensionalData.Lookups
using DimensionalData.Dimensions

@testset "FacedGridLookup" begin
    ni, nj, nfaces = 4, 5, 3

    # Create coordinate matrices (simulating cubed sphere)
    X_coords = zeros(ni, nj, nfaces)
    Y_coords = zeros(ni, nj, nfaces)
    for f in 1:nfaces, j in 1:nj, i in 1:ni
        X_coords[i, j, f] = (f - 1) * 60 + i * 10.0
        Y_coords[i, j, f] = j * 15.0 - 45.0
    end

    @testset "Construction" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)

        @test parent(l) == 1:ni
        @test length(l) == ni
        @test size(l) == (ni,)
        @test l[1] == 1  # Returns axis value, not coord
        @test hasinternaldimensions(l)
        @test size(coords(l)) == (ni, nj, nfaces)
        @test coord_dim(l) == X()
        @test grid_position(l) == 1
        @test order(l) == Unordered()
    end

    @testset "Convenience constructor" begin
        # Auto-generate data as 1:n
        l = FacedGridLookup(X_coords, X(), 1)
        @test parent(l) == Base.OneTo(ni)
        @test length(l) == ni
    end

    @testset "Validation" begin
        # Mismatched data length should error
        @test_throws ArgumentError FacedGridLookup(1:10, X_coords, X(), 1)
    end

    @testset "Slicing along own axis" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)

        l2 = l[2:3]
        @test parent(l2) == 2:3
        @test length(l2) == 2
        @test size(coords(l2)) == (2, nj, nfaces)
    end

    @testset "Slicing coords (face selection)" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)

        # Slice along face dimension (position 3)
        l2 = slice_coords(l, 3, 2)
        @test parent(l2) == 1:ni  # data unchanged
        @test size(coords(l2)) == (ni, nj)  # coords now 2D
        @test coords(l2) == X_coords[:, :, 2]
    end

    @testset "Bounds" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)
        b = bounds(l)

        @test b[1] == minimum(X_coords)
        @test b[2] == maximum(X_coords)

        # Bounds update after slicing
        l2 = l[1:2]
        b2 = bounds(l2)
        @test b2[1] == minimum(X_coords[1:2, :, :])
        @test b2[2] == maximum(X_coords[1:2, :, :])
    end

    @testset "Rebuild" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)

        # Rebuild with new data and coords (both must be consistent)
        new_coords = X_coords[1:2, :, :]
        l2 = rebuild(l; data=1:2, coords=new_coords)
        @test parent(l2) == 1:2
        @test size(coords(l2)) == (2, nj, nfaces)

        # Rebuild with new coords only (data unchanged)
        new_coords2 = X_coords[:, :, 1:2]
        l3 = rebuild(l; coords=new_coords2)
        @test size(coords(l3)) == (ni, nj, 2)
        @test parent(l3) == 1:ni
    end

    @testset "Internal dimensions" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)
        @test dims(l) == (X(),)

        l2 = FacedGridLookup(1:nj, Y_coords, Y(), 2)
        @test dims(l2) == (Y(),)
    end

    @testset "reducelookup" begin
        l = FacedGridLookup(1:ni, X_coords, X(), 1)
        r = Lookups.reducelookup(l)
        @test r isa NoLookup
    end

    @testset "DimArray integration" begin
        I_lookup = FacedGridLookup(1:ni, X_coords, X(), 1)
        J_lookup = FacedGridLookup(1:nj, Y_coords, Y(), 2)

        A = DimArray(rand(ni, nj, nfaces), (Dim{:I}(I_lookup), Dim{:J}(J_lookup), Dim{:face}(1:nfaces)))

        @test size(A) == (ni, nj, nfaces)
        @test lookup(A, :I) isa FacedGridLookup
        @test length(lookup(A, :I)) == ni
        @test size(coords(lookup(A, :I))) == (ni, nj, nfaces)
    end
end
