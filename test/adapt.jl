using DimensionalData, Test, Unitful, Adapt

using DimensionalData.LookupArrays, DimensionalData.Dimensions

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

@testset "LookupArray" begin
    l = Sampled([1:10...]; metadata=Metadata(:a=>"1", :b=>"2"))
    l1 = Adapt.adapt(CustomArray, l)
    @test parent(parent(l1)) isa CustomArray
    @test parent(parent(l1)).arr == [1:10...]
    @test metadata(l1) == NoMetadata()
    l = Categorical('a':1:'n'; metadata=Metadata(:a=>"1", :b=>"2"))
    l1 = Adapt.adapt(CustomArray, l)
    @test parent(parent(l1)) isa StepRange
    @test metadata(l1) == NoMetadata()
    l = Categorical(['a', 'e', 'n']; metadata=Metadata(:a=>"1", :b=>"2"))
    l1 = Adapt.adapt(CustomArray, l)
    @test parent(parent(l1)) isa CustomArray
    @test metadata(l1) == NoMetadata()
    l = NoLookup(Base.OneTo(10))
    l1 = Adapt.adapt(CustomArray, l)
    @test parent(parent(l1)) isa Base.OneTo
    l = AutoLookup()
    l1 = Adapt.adapt(CustomArray, l)
    @test parent(l1) isa AutoIndex
end

@testset "Dimension" begin
    d = X(Sampled([1:10...]; metadata=Metadata(:a=>"1", :b=>"2")))
    d1 = Adapt.adapt(CustomArray, d)
    @test parent(parent(d1)) isa CustomArray
    @test parent(parent(d1)).arr == [1:10...]
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
