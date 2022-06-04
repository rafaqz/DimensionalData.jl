var documenterSearchIndex = {"docs":
[{"location":"api/#API-1","page":"API","title":"API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"To use the functionality of DimensionalData in your module, dispatch on AbstractDimensionalArray and AbstractDimension.","category":"page"},{"location":"api/#Core-types-1","page":"API","title":"Core types","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Arrays:","category":"page"},{"location":"api/#","page":"API","title":"API","text":"AbstractDimensionalArray\r\nDimensionalArray","category":"page"},{"location":"api/#DimensionalData.AbstractDimensionalArray","page":"API","title":"DimensionalData.AbstractDimensionalArray","text":"Parent type for all dimensional arrays.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.DimensionalArray","page":"API","title":"DimensionalData.DimensionalArray","text":"DimensionalArray(data, dims, refdims, name)\n\nThe main subtype of AbstractDimensionalArray. Maintains and updates its dimensions through transformations and moves dimensions to refdims after reducing operations (like e.g. mean).\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"Dimensions:","category":"page"},{"location":"api/#","page":"API","title":"API","text":"AbstractDimension\r\nDependentDim\r\nIndependentDim\r\nCategoricalDim\r\nXDim\r\nYDim\r\nZDim\r\nTimeDim\r\nX\r\nY\r\nZ\r\nTi\r\nDim\r\n@dim","category":"page"},{"location":"api/#DimensionalData.DependentDim","page":"API","title":"DimensionalData.DependentDim","text":"Abstract supertype for Dependent dimensions. Will plot on the Y axis.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.IndependentDim","page":"API","title":"DimensionalData.IndependentDim","text":"Abstract supertype for independent dimensions. Will plot on the X axis.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.CategoricalDim","page":"API","title":"DimensionalData.CategoricalDim","text":"Abstract supertype for categorical dimensions. \n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.XDim","page":"API","title":"DimensionalData.XDim","text":"Abstract parent type for all X dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.YDim","page":"API","title":"DimensionalData.YDim","text":"Abstract parent type for all Y dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.ZDim","page":"API","title":"DimensionalData.ZDim","text":"Abstract parent type for all Z dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.TimeDim","page":"API","title":"DimensionalData.TimeDim","text":"Abstract parent type for all time dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.X","page":"API","title":"DimensionalData.X","text":"X dimension. `X <: XDim <: IndependentDim\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Y","page":"API","title":"DimensionalData.Y","text":"Y dimension. `Y <: YDim <: DependentDim\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Z","page":"API","title":"DimensionalData.Z","text":"Z dimension. `Z <: ZDim <: Dimension\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Ti","page":"API","title":"DimensionalData.Ti","text":"Time dimension. `Ti <: TimeDim <: IndependentDim \n\nTime is already used by Dates, so we use Ti to avoid clashing.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Dim","page":"API","title":"DimensionalData.Dim","text":"A generic dimension. For use when custom dims are required when loading data from a file. The sintax is ugly and verbose to use for indexing, ie Dim{:lat}(1:9) rather than Lat(1:9). This is the main reason they are not the only type of dimension availabile.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.@dim","page":"API","title":"DimensionalData.@dim","text":"@dim typ [supertype=Dimension] [name=string(typ)] [shortname=string(typ)]\n\nMacro to easily define specific dimensions.\n\nExample:\n\n@dim Lat \"Lattitude\" \"lat\"\n@dim Lon XDim \"Longitude\"\n\n\n\n\n\n","category":"macro"},{"location":"api/#Getting-basic-info-1","page":"API","title":"Getting basic info","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"These useful functions for obtaining information from your dimensional data:","category":"page"},{"location":"api/#","page":"API","title":"API","text":"dims\r\nhasdim\r\ndimnum\r\nname\r\nval","category":"page"},{"location":"api/#DimensionalData.dims","page":"API","title":"DimensionalData.dims","text":"dims(x)\n\nReturn a tuple of the dimensions for a dataset. These can contain the coordinate ranges if bounds() and select() are to be used, or you want them to be shown on plots in place of the array indices.\n\nThey can also contain a units string or unitful unit to use and plot dimension units.\n\nThis is the only method required for this package to work. It probably requires defining a dims field on your object to store dims in.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.hasdim","page":"API","title":"DimensionalData.hasdim","text":"hasdim(A, lookup)\n\nCheck if an object or tuple contains an Dimension, or a tuple of dimensions.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.dimnum","page":"API","title":"DimensionalData.dimnum","text":"dimnum(A, lookup)\n\nGet the number(s) of Dimension(s) as ordered in the dimensions of an object.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.name","page":"API","title":"DimensionalData.name","text":"name(x)\n\nGet the name of data or a dimension.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.val","page":"API","title":"DimensionalData.val","text":"val(x)\n\nReturn the contained value of a wrapper object, otherwise just returns the object.\n\n\n\n\n\n","category":"function"},{"location":"api/#","page":"API","title":"API","text":"As well as others related to obtained metadata:","category":"page"},{"location":"api/#","page":"API","title":"API","text":"bounds\r\nlabel\r\nmetadata\r\nrefdims\r\nshortname\r\nunits\r\ndata","category":"page"},{"location":"api/#DimensionalData.bounds","page":"API","title":"DimensionalData.bounds","text":"bounds(x, [dims])\n\nReturn the bounds of all dimensions of an object, of a specific dimension, or of a tuple of dimensions.\n\nBounds are allways return in ascending order.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.label","page":"API","title":"DimensionalData.label","text":"label(x)\n\nGet a plot label for data or a dimension. This will include the name and units if they exist, and anything else that should be shown on a plot.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.metadata","page":"API","title":"DimensionalData.metadata","text":"metadata(x)\n\nReturn the metadata of a dimension or data object.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.refdims","page":"API","title":"DimensionalData.refdims","text":"refdims(x)\n\nReference dimensions for an array that is a slice or view of another array with more dimensions.\n\nslicedims(a, dims) returns a tuple containing the current new dimensions and the new reference dimensions. Refdims can be stored in a field or disgarded, as it is mostly to give context to plots. Ignoring refdims will simply leave some captions empty.  \n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.shortname","page":"API","title":"DimensionalData.shortname","text":"shortname(x)\n\nGet the short name of array data or a dimension.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.units","page":"API","title":"DimensionalData.units","text":"units(x)\n\nReturn the units of a dimension. This could be a string, a unitful unit, or nothing.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.data","page":"API","title":"DimensionalData.data","text":"data(x)\n\nReturn the data wrapped by the dimentional array. This may not be the same as Base.parent, as it should never include data outside the bounds of the dimensions.\n\nIn a disk based AbstractDimensionalArray, data may need to load data from disk.\n\n\n\n\n\n","category":"function"},{"location":"api/#Selectors-1","page":"API","title":"Selectors","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Selector\r\nAt\r\nNear\r\nBetween","category":"page"},{"location":"api/#DimensionalData.Selector","page":"API","title":"DimensionalData.Selector","text":"Selectors indicate that index values are not indices, but points to be selected from the dimension values, such as DateTime objects on a Time dimension.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.At","page":"API","title":"DimensionalData.At","text":"At(x)\n\nSelector that exactly matches the value on the passed-in dimensions, or throws an error. For ranges and arrays, every value must match an existing value - not just the end points.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Near","page":"API","title":"DimensionalData.Near","text":"Near(x)\n\nSelector that selects the nearest index to its contained value(s)\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Between","page":"API","title":"DimensionalData.Between","text":"Between(a, b)\n\nSelector that retreive all indices located between 2 values.\n\n\n\n\n\n","category":"type"},{"location":"api/#Grids-1","page":"API","title":"Grids","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Grid\r\nIndependentGrid\r\nAlignedGrid\r\nBoundedGrid\r\nRegularGrid\r\nCategoricalGrid\r\nUnknownGrid\r\nDependentGrid\r\nTransformedGrid","category":"page"},{"location":"api/#DimensionalData.Grid","page":"API","title":"DimensionalData.Grid","text":"Traits describing the grid type of a dimension.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.IndependentGrid","page":"API","title":"DimensionalData.IndependentGrid","text":"A grid dimension that is independent of other grid dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.AlignedGrid","page":"API","title":"DimensionalData.AlignedGrid","text":"An AlignedGrid grid without known regular spacing. These grids will generally be paired with a vector of coordinates along the dimension, instead of a range.\n\nBounds are given as the first and last points, which omits the step of one cell, as it is not known. To fix this use either a BoundedGrid with specified starting bounds or a RegularGrid with a known constand cell step.\n\nFields\n\norder::Order: Order trait indicating array and index order\nlocus::Locus: Locus trait indicating the position of the indexed point within the cell step\nsampling::Sampling: Sampling trait indicating wether the grid cells are single samples or means\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.BoundedGrid","page":"API","title":"DimensionalData.BoundedGrid","text":"An alligned grid without known regular spacing and tracked bounds. These grids will generally be paired with a vector of coordinates along the dimension, instead of a range.\n\nAs the size of the cells is not known, the bounds must be actively tracked.\n\nFields\n\norder::Order: Order trait indicating array and index order\nlocus::Locus: Locus trait indicating the position of the indexed point within the cell step\nsampling::Sampling: Sampling trait indicating wether the grid cells are single samples or means\nbounds: the outer edges of the grid (different to the first and last coordinate).\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.RegularGrid","page":"API","title":"DimensionalData.RegularGrid","text":"An AlignedGrid where all cells are the same size and evenly spaced.\n\nFields\n\norder::Order: Order trait indicating array and index order\nlocus::Locus: Locus trait indicating the position of the indexed point within the cell step\nsampling::Sampling: Sampling trait indicating wether the grid cells are single samples or means\nstep::Number: the size of a grid step, such as 1u\"km\" or Month(1)\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.CategoricalGrid","page":"API","title":"DimensionalData.CategoricalGrid","text":"A grid dimension where the values are categories.\n\nFields\n\norder: Order trait indicating array and index order\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.UnknownGrid","page":"API","title":"DimensionalData.UnknownGrid","text":"Fallback grid type\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.DependentGrid","page":"API","title":"DimensionalData.DependentGrid","text":"Traits describing a grid dimension that is dependent on other grid dimensions.\n\nIndexing into a dependent dimension must provide all other dependent dimensions.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.TransformedGrid","page":"API","title":"DimensionalData.TransformedGrid","text":"Grid type using an affine transformation to convert dimension from dim(grid) to dims(array).\n\nFields\n\ndims: a tuple containing dimenension types or symbols matching the order         needed by the transform function.\nsampling: a Sampling trait indicating wether the grid cells are sampled points or means\n\n\n\n\n\n","category":"type"},{"location":"api/#","page":"API","title":"API","text":"Tracking the order of arrays and indices:","category":"page"},{"location":"api/#","page":"API","title":"API","text":"Unordered\r\nOrdered","category":"page"},{"location":"api/#DimensionalData.Unordered","page":"API","title":"DimensionalData.Unordered","text":"Trait indicating that the array or dimension has no order.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Ordered","page":"API","title":"DimensionalData.Ordered","text":"Trait container for dimension and array ordering in AlignedGrid.\n\nThe default is Ordered(Forward(), Forward())\n\nAll combinations of forward and reverse order for data and indices seem to occurr in real datasets, as strange as that seems. We cover these possibilities by specifying the order of both explicitly.\n\nKnowing the order of indices is important for using methods like searchsortedfirst() to find indices in sorted lists of values. Knowing the order of the data is then required to map to the actual indices. It's also used to plot the data later - which always happens in smallest to largest order.\n\nBase also defines Forward and Reverse, but they seem overly complicated for our purposes.\n\n\n\n\n\n","category":"type"},{"location":"api/#Loci-1","page":"API","title":"Loci","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"Locus\r\nCenter\r\nStart\r\nEnd\r\nUnknownLocus","category":"page"},{"location":"api/#DimensionalData.Locus","page":"API","title":"DimensionalData.Locus","text":"Locii indicate the position of index values in grid cells.\n\nLocii are often Start for time series, but often Center for spatial data.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Center","page":"API","title":"DimensionalData.Center","text":"Indicates dimension index that matches the center coordinates/time/position.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.Start","page":"API","title":"DimensionalData.Start","text":"Indicates dimension index that matches the start coordinates/time/position.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.End","page":"API","title":"DimensionalData.End","text":"Indicates dimension index that matches the end coordinates/time/position.\n\n\n\n\n\n","category":"type"},{"location":"api/#DimensionalData.UnknownLocus","page":"API","title":"DimensionalData.UnknownLocus","text":"Indicates dimension where the index position is not known.\n\n\n\n\n\n","category":"type"},{"location":"api/#Low-level-API-1","page":"API","title":"Low-level API","text":"","category":"section"},{"location":"api/#","page":"API","title":"API","text":"DimensionalData.rebuild\r\nDimensionalData.formatdims\r\nDimensionalData.reducedims\r\nDimensionalData.slicedims","category":"page"},{"location":"api/#DimensionalData.rebuild","page":"API","title":"DimensionalData.rebuild","text":"rebuild(x::AbstractDimensionalArray, data, [dims], [refdims], [name])\nrebuild(x::AbstractDimensionalArray, data, [name])\nrebuild(x::AbstractDimension, val, [grid], [metadata])\nrebuild(x; kwargs...)\n\nRebuild an object struct with updated values.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.formatdims","page":"API","title":"DimensionalData.formatdims","text":"formatdims(A, dims)\n\nFormat the passed-in dimension(s).\n\nMostily this means converting indexes of tuples and UnitRanges to LinRange, which is easier to handle internally. Errors are also thrown if dims don't match the array dims or size.\n\nIf a Grid hasn't been specified, a grid type is chosen based on the type and element type of the index:\n\nAbstractRange become RegularGrid\nAbstractArray become AlignedGrid\nAbstractArray of Symbol or String become CategoricalGrid\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.reducedims","page":"API","title":"DimensionalData.reducedims","text":"Replace the specified dimensions with an index of length 1 to match a new array size where the dimension has been reduced to a length of 1, but the number of dimensions has not changed.\n\nUsed in mean, reduce, etc.\n\nGrid traits are also updated to correspond to the change in cell step, sampling type and order.\n\n\n\n\n\n","category":"function"},{"location":"api/#DimensionalData.slicedims","page":"API","title":"DimensionalData.slicedims","text":"Slice the dimensions to match the axis values of the new array\n\nAll methods returns a tuple conatining two tuples: the new dimensions, and the reference dimensions. The ref dimensions are no longer used in the new struct but are useful to give context to plots.\n\nCalled at the array level the returned tuple will also include the previous reference dims attached to the array.\n\n\n\n\n\n","category":"function"},{"location":"developer/#For-package-developers-1","page":"For Developers","title":"For package developers","text":"","category":"section"},{"location":"developer/#Goals:-1","page":"For Developers","title":"Goals:","text":"","category":"section"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Maximum extensibility: always use method dispatch. Regular types over special syntax. Recursion over @generated.\nFlexibility: dims and selectors are parametric types with multiple uses\nAbstraction: never dispatch on concrete types, maximum re-usability of methods\nClean, readable syntax. Minimise required parentheses, minimise of exported methods, and instead extend Base methods whenever possible.\nMinimal interface: implementing a dimension-aware type should be easy.\nFunctional style: structs are always rebuilt, and other than the array data, fields are not mutated in place.\nLeast surprise: everything works the same as in Base, but with named dims. If a method accepts numeric indices or dims=X in base, you should be able to use DimensionalData.jl dims.\nType stability: dimensional methods should be type stable more often than Base methods\nZero cost dimensional indexing a[Y(4), X(5)] of a single value.\nLow cost indexing for range getindex and views: these cant be zero cost as dim ranges have to be updated.\nPlotting is easy: data should plot sensibly and correctly with useful labels - after all transformations using dims or indices\nPrioritise spatial data: other use cases are a free bonus of the modular approach.","category":"page"},{"location":"developer/#Why-this-package-1","page":"For Developers","title":"Why this package","text":"","category":"section"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Why not AxisArrays.jl or NamedDims.jl?","category":"page"},{"location":"developer/#Structure-1","page":"For Developers","title":"Structure","text":"","category":"section"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Both AxisArrays and NamedDims use concrete types for dispatch on arrays, and for dimension type Axis in AxisArrays. This makes them hard to extend.","category":"page"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Its a little easier with DimensionalData.jl. You can inherit from AbstractDimensionalArray, or just implement dims and rebuild methods. Dims and selectors in DimensionalData.jl are also extensible. Recursive primitive methods allow inserting whatever methods you want to add extra types. @generated is only used to match and permute arbitrary tuples of types, and contain no type-specific details. The @generated functions in AxisArrays internalise axis/index conversion behaviour preventing extension in external packages and scripts.","category":"page"},{"location":"developer/#Syntax-1","page":"For Developers","title":"Syntax","text":"","category":"section"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"AxisArrays.jl is verbose by default: a[Axis{:y}(1)] vs a[Y(1)] used here. NamedDims.jl has concise syntax, but the dimensions are no longer types.","category":"page"},{"location":"developer/#Data-types-and-the-interface-1","page":"For Developers","title":"Data types and the interface","text":"","category":"section"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"DimensionalData.jl provides the concrete DimenstionalArray type. But it's core purpose is to be easily used with other array types.","category":"page"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Some of the functionality in DimensionalData.jl will work without inheriting from AbstractDimensionalArray. The main requirement define a dims method that returns a Tuple of AbstractDimension that matches the dimension order and axis values of your data. Define rebuild, and base methods for similar and parent if you want the metadata to persist through transformations (see the DimensionalArray and AbstractDimensionalArray types). A refdims method returns the lost dimensions of a previous transformation, passed in to the rebuild method. refdims can be discarded, the main loss being plot labels.","category":"page"},{"location":"developer/#","page":"For Developers","title":"For Developers","text":"Inheriting from AbstractDimensionalArray will give all the functionality of using DimensionalArray.","category":"page"},{"location":"course/#Crash-course-1","page":"Crash course","title":"Crash course","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"This is brief a tutorial for DimensionalData.jl.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"All main functionality is explained here, but the full list of features is listed at the API page.","category":"page"},{"location":"course/#Dimensions-and-DimensionalArrays-1","page":"Crash course","title":"Dimensions and DimensionalArrays","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"The core type of DimensionalData.jl is DimensionalArray, which bundles a standard array with named and indexed dimensions. The dimensions are any AbstractDimension, and types that inherit from it, such as Ti, X, Y, Z, the generic Dim{:x} or others that you define manually using the @dim macro.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A DimensionalArray dimensions are constructed by:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"using DimensionalData, Dates\r\nt = Ti(DateTime(2001):Month(1):DateTime(2001,12))\r\nx = X(10:10:100)","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Here both X and Ti are dimensions from the DimensionalData module. The currently exported predefined dimensions are X, Y, Z, Ti, with Ti an alias of DimensionalData.Time (to avoid the conflict with Dates.Time).","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"We pass a Tuple of the dimensions to make a DimensionalArray:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A = DimensionalArray(rand(12, 10), (t, x))","category":"page"},{"location":"course/#Indexing-the-array-by-name-and-index-1","page":"Crash course","title":"Indexing the array by name and index","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"These dimensions can then be used to index the array by name, without having to worry about the order of the dimensions.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"The simplest case is to select a dimension by index. Let's say every 2nd point of the Ti dimension and every 3rd point of the X dimension. This is done with the simple Ti(range) syntax like so:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A[X(1:3:end), Ti(1:2:end)]","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Of course, when specifying only one dimension, all elements of the other dimensions are assumed to be included:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A[X(1:3:10)]","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"info: Indexing\nIndexing AbstractDimensionalArrays works with getindex, setindex! and view. The result is still an AbstracDimensionalArray.","category":"page"},{"location":"course/#Selecting-by-name-and-value-1","page":"Crash course","title":"Selecting by name and value","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"The above example is useful because one does not have to care about the ordering of the dimensions. But arguably more useful is to be able to select a dimension by its values. For example, we would like to get all values of A where the X dimension is between two values.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Selecting by value in DimensionalData is always done with the selectors, all of which are listed in the Selectors page. This avoids the ambiguity of what happens when the index values of the dimension are also integers (like the case here for the dimension X).","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"For simplicity, here we showcase the Between selector but  others also exist, like At or Near.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A[X(Between(12, 35)), Ti(Between(Date(2001, 5), Date(2001, 7)))]","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Notice that the selectors have to be applied to a dimension (alternative syntax is selector <| Dim, which literally translates to Dim(selector)).","category":"page"},{"location":"course/#Selecting-by-position-1","page":"Crash course","title":"Selecting by position","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"So far, the selection protocols we have mentioned work by specifying the name of the dimension, without worry about the order.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"However normal indexing also works by specifying dimensions by position. This functionality also covers the selector functions.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Continuing to use A we defined above, you can see this by comparing the statements without and with names:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A[:, Between(12, 35)] == A[X(Between(12, 35))]\r\nA[:, 1:5] == A[X(1:5)]\r\nA[1:5, :] == A[Ti(1:5)]","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"etc. Of course, in this approach it is necessary to specify all dimensions by position, one cannot leave some unspecified.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"In addition, to attempt supporting as much as base Julia functionality as possible, single index access like in standard Array. For example","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"A[1:5]","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"selects the first 5 entries of the underlying numerical data. In the case that A has only one dimension, this kind of indexing retains the dimension.","category":"page"},{"location":"course/#Specifying-dims-by-dimension-name-1","page":"Crash course","title":"Specifying dims by dimension name","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"In many Julia functions like size, sum, you can specify the dimension along which to perform the operation, as an Int. It is also possible to do this using Dim types with AbstractDimensionalArray by specifying the dimension by its type, for example:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"sum(A; dims = X)","category":"page"},{"location":"course/#Numeric-operations-on-dimension-arrays-and-dimensions-1","page":"Crash course","title":"Numeric operations on dimension arrays and dimensions","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"We have tried to make all numeric operations on a AbstractDimensionalArray match  base Julia as much as possible. Standard broadcasting and other type of operations  across dimensional arrays typically perform as expected while still  returning an AbstractDimensionalArray type with correct dimensions.","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"In cases where you would like to do some operation on the dimension index, e.g.  take the cosines of the values of the dimension X while still keeping the dimensional  information of X, you can use the syntax:","category":"page"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"DimensionalArray(cos, x)","category":"page"},{"location":"course/#Referenced-dimensions-1","page":"Crash course","title":"Referenced dimensions","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"The reference dimensions record the previous dimensions that an array was selected from. These can be use for plot labelling, and tracking array changes.","category":"page"},{"location":"course/#Grid-functionality-1","page":"Crash course","title":"Grid functionality","text":"","category":"section"},{"location":"course/#","page":"Crash course","title":"Crash course","text":"Coming soon.","category":"page"},{"location":"#","page":"Introduction","title":"Introduction","text":"DimensionalData","category":"page"},{"location":"#DimensionalData","page":"Introduction","title":"DimensionalData","text":"DimensionalData\n\n(Image: ) (Image: ) (Image: Build Status) (Image: Codecov)\n\nDimensionalData.jl provides tools and abstractions for working with datasets that have named dimensions. It's a pluggable, generalised version of AxisArrays.jl with a cleaner syntax, and additional functionality found in NamedDimensions.jl. It has similar goals to pythons xarray, and is primarily written for use with spatial data in GeoData.jl.\n\ninfo: Status\nThis is a work in progress under active development, it may be a while before the interface stabilises and things are fully documented.\n\nDimensions\n\nDimensions are just wrapper types. They store the dimension index and define details about the grid and other metadata, and are also used to index into the array, wrapping a value or a Selector. X, Y, Z and Ti are the exported defaults.\n\nA generalised Dim type is available to use arbitrary symbols to name dimensions. Custom dimensions can be defined using the @dim macro.\n\nWe can use dim wrappers for indexing, so that the dimension order in the underlying array does not need to be known:\n\na[X(1:10), Y(1:4)]\n\nThe core component is the AbstractDimension, and types that inherit from it, such as Time, X, Y, Z, the generic Dim{:x} or others you define manually using the @dim macro.\n\nDims can be used for indexing and views without knowing dimension order: a[X(20)], view(a, X(1:20), Y(30:40)) and for indicating dimesions to reduce mean(a, dims=Time), or permute permutedims(a, [X, Y, Z, Time]) in julia Base and Statistics functions that have dims arguments.\n\nSelectors\n\nSelectors find indices in the dimension based on values At, Near, or Between the index value(s). They can be used in getindex, setindex! and view to select indices matching the passed in value(s)\n\nAt(x) : get indices exactly matching the passed in value(s)\nNear(x) : get the closest indices to the passed in value(s)\nBetween(a, b) : get all indices between two values (inclusive)\n\nWe can use selectors with dim wrappers:\n\na[X(Between(1, 10)), Y(At(25.7))]\n\nWithout dim wrappers selectors must be in the right order:\n\nusin Unitful\na[Near(23u\"s\"), Between(10.5u\"m\", 50.5u\"m\")]\n\nIt's easy to write your own custom Selector if your need a different behaviour.\n\nExample usage:\n\nusing Dates, DimensionalData\ntimespan = DateTime(2001,1):Month(1):DateTime(2001,12)\nA = DimensionalArray(rand(12,10), (Ti(timespan), X(10:10:100)))\n\njulia> A[X(Near(35)), Ti(At(DateTime(2001,5)))]\n0.658404535807791\n\njulia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)]\nDimensionalArray with dimensions:\n X: 20:10:50\nand referenced dimensions:\n Time (type Ti): 2001-05-01T00:00:00\nand data: 4-element Array{Float64,1}\n[0.456175, 0.737336, 0.658405, 0.520152]\n\nDim types or objects can be used instead of a dimension number in many Base and Statistics methods:\n\nMethods where dims can be used containing indices or Selectors\n\ngetindex, setindex! view\n\nMethods where dims can be used\n\nsize, axes, firstindex, lastindex\ncat\nreverse\ndropdims\nreduce, mapreduce\nsum, prod, maximum, minimum, \nmean, median, extrema, std, var, cor, cov\npermutedims, adjoint, transpose, Transpose\nmapslices, eachslice\n\nExample usage:\n\nA = DimensionalArray(rand(20,10), (X, Y))\nsize(A, Y)\nmean(A, dims=X)\nstd(A; dims=Y())\n\n\n\n\n\n","category":"module"},{"location":"#","page":"Introduction","title":"Introduction","text":"To learn how to use this package, see the Crash course.","category":"page"}]
}