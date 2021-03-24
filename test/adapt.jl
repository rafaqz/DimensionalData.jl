using DimensionalData, Test, Unitful, Adapt

struct CustomArray{T,N} <: AbstractArray{T,N}
    arr::Array
end

CustomArray(x::Array{T,N}) where {T,N} = CustomArray{T,N}(x)
Adapt.adapt_storage(::Type{<:CustomArray}, xs::Array) = CustomArray(xs)

Base.size(x::CustomArray, y...) = size(x.arr, y...)
Base.getindex(x::CustomArray, y...) = getindex(x.arr, y...)
Base.count(x::CustomArray) = count(x.arr)

@testset "Metadata" begin
    @test adapt(CustomArray, Metadata(:a=>"1", :b=>"2")) == NoMetadata()
end

@testset "Dimension" begin
    d = X([1:10...]; metadata=Metadata(:a=>"1", :b=>"2"))
    d1 = adapt(CustomArray, d)
    @test val(d1) isa CustomArray
    @test val(d1).arr == [1:10...]
    @test metadata(d1) == NoMetadata()
end

@testset "DimArray" begin
    A = rand(4, 5)
    da = DimArray(A, (X, Y))
    da1 = adapt(CustomArray, da)
    @test parent(da1) isa CustomArray
    @test parent(da1).arr == A
    @test metadata(da1) == NoMetadata()
end

@testset "DimStack" begin
    A = rand(4, 5)
    B = rand(4, 5)
    ds = DimStack((a=A, b=B), (X, Y))
    ds1 = adapt(CustomArray, ds)
    @test parent(ds1[:a]) isa CustomArray
    @test parent(ds1[:a]).arr == A
    @test parent(ds1[:b]) isa CustomArray
    @test parent(ds1[:b]).arr == B
    @test metadata(ds) == NoMetadata()
end
