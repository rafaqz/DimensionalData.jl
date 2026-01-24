### Shared utils

"""
    refdims_title(A::AbstractDimArray)
    refdims_title(refdims::Tuple)
    refdims_title(refdim::Dimension)

Generate a title string based on reference dimension values.
"""
function refdims_title end
refdims_title(A::AbstractArray; kw...) = refdims_title(refdims(A); kw...)
function refdims_title(refdims::Tuple; kw...)
    join(map(rd -> refdims_title(rd; kw...), refdims), ", ")
end
function refdims_title(refdim::Dimension; kw...)
    string(label(refdim), ": ", refdims_title(lookup(refdim), refdim; kw...))
end
function refdims_title(lookup::AbstractSampled, refdim::Dimension; kw...)
    start, stop = map(string, bounds(refdim))
    if start == stop
        start
    else
         "$start to $stop"
    end
end
function refdims_title(lookup::Lookup, refdim::Dimension; kw...)
    if parent(refdim) isa AbstractArray
        string(first(parent(refdim)))
    else
        string(parent(refdim))
    end
end

const PLOT_DIMENSION_ORDER = (TimeDim, XDim, IndependentDim, IndependentDim, YDim, ZDim, DependentDim, DependentDim, Dimension, Dimension, Dimension)
forward_order_plot_dims(x) = dims(dims(x), PLOT_DIMENSION_ORDER)
reverse_order_plot_dims(x) = reverse(forward_order_plot_dims(reverse(dims(x))))
