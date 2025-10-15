module DimensionalDataDataInterpolationsExt

using DimensionalData
using DataInterpolations

function (Itp::Type{<:DataInterpolations.AbstractInterpolation})(
    data::AbstractDimVector,
    args...;
    kw...
)
    return Itp(
        parent(data),
        _prepare_dim(data),
        args...;
        kw...
    )
end

# Make sure we have a Center locus, then unwrap 
_prepare_dim(d::AbstractDimVector) = parent(maybeshiftlocus(Center(), lookup(d, 1)))

doctargets = [
    :LinearInterpolation,
    :QuadraticInterpolation,
    :LagrangeInterpolation,
    :AkimaInterpolation,
    :ConstantInterpolation,
    :QuadraticSpline,
    :CubicSpline,
	:BSplineInterpolation,
    :PCHIPInterpolation
]

for doctarget in doctargets
    @eval begin
        """
        ```
        $($doctarget)(
            ut::DimensionalData.AbstractDimVector,
            ...; ...
        )
        ```

        The two positional arguments `u, t`
        in the original method definitions
        are assigned the parent array of `ut`
        and the `Dimension` of `ut` respectively.

        Remaining positional and keyword arguments are as per the original
        `DataInterpolations.$($doctarget)` method definitions.

        This interoperability between
        DimensionalData.jl and DataInterpolations.jl
        is experimental and under development.
        """
        $(doctarget)
    end
end

function DataInterpolations.QuadraticInterpolation(
    data::AbstractDimVector,
    mode::Symbol,
    args...;
    kw...
)
    return QuadraticInterpolation(
        parent(data),
        _prepare_dim(data),
        mode,
        args...;
        kw...
    )
end

"""
```
PCHIPInterpolation(
    ut::DimensionalData.AbstractDimVector,
    ...; ...
)
```

The two positional arguments `u, t`
in the original method definitions
are assigned the parent array of `ut`
and the `Dimension` of `ut` respectively.

Remaining positional and keyword arguments are as per the original
`DataInterpolationsQuadraticInterpolation` method definitions.

This interoperability between
DimensionalData.jl and DataInterpolations.jl
is experimental and under development.
"""
function DataInterpolations.PCHIPInterpolation(
    data::AbstractDimVector,
    args...;
    kw...
)
    return PCHIPInterpolation(
        parent(data),
        _prepare_dim(data),
        args...;
        kw...
    )
end

"""
```
CubicHermiteSpline(
    du::AbstractVector,
    ut::DimensionalData.AbstractDimVector,
    ...; ...
)
```

The two positional arguments `u, t`
in the original method definitions
are assigned the parent array of `ut`
and the `Dimension` of `ut` respectively.

Remaining positional and keyword arguments are as per the original
`DataInterpolationsQuadraticInterpolation` method definitions.

This interoperability between
DimensionalData.jl and DataInterpolations.jl
is experimental and under development.
"""
function DataInterpolations.CubicHermiteSpline(
    du::AbstractVector,
    data::AbstractDimVector,
    args...;
    kw...
)
    return CubicHermiteSpline(
        du,
        parent(data),
        _prepare_dim(data),
        args...;
        kw...
    )
end

"""
```
QuinticHermiteSpline(
    ddu::AbstractVector,
    du::AbstractVector,
    ut::DimensionalData.AbstractDimVector,
    ...; ...
)
```

The two positional arguments `u, t`
in the original method definitions
are assigned the parent array of `ut`
and the `Dimension` of `ut` respectively.

Remaining positional and keyword arguments are as per the original
`DataInterpolationsQuadraticInterpolation` method definitions.

This interoperability between
DimensionalData.jl and DataInterpolations.jl
is experimental and under development.
"""
function DataInterpolations.QuinticHermiteSpline(
    ddu::AbstractVector,
    du::AbstractVector,
    data::AbstractDimVector,
    args...;
    kw...
)
    return QuinticHermiteSpline(
        ddu,
        du,
        parent(data),
        _prepare_dim(data),
        args...;
        kw...
    )
end

end
