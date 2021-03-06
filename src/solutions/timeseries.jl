
using Base: Indices, tail

struct TimeSeries{T} <: AbstractArray{T,1}
    n::Int
    t::Vector{T}

    Δt::T
    step::Int

    function TimeSeries{T}(n, Δt, step) where {T}
        @assert T <: Real
        @assert n ≥ 0
        @assert step > 0

        t = zeros(T, n+1)
        new(n, t, Δt, step)
    end

    function TimeSeries{T}(n, t, Δt, step) where {T}
        new(n, t, Δt, step)
    end
end

function TimeSeries(n::Int, Δt::T, step::Int=1) where {T}
    return TimeSeries{T}(n, Δt, step)
end

function TimeSeries(t::Vector{T}, step=1) where {T}
    @assert length(t) ≥ 2
    n  = length(t)-1
    Δt = (t[2] - t[1]) / step
    return TimeSeries{T}(n, t, Δt, step)
end

Base.:(==)(ts1::TimeSeries, ts2::TimeSeries) = (
                                ts1.n  == ts2.n
                             && ts1.t  == ts2.t
                             && ts1.Δt == ts2.Δt
                             && ts1.step == ts2.step)

Base.parent(ts::TimeSeries) = ts.t
Base.eltype(ts::TimeSeries{T}) where {T} = T
Base.ndims(ts::TimeSeries) = 1

Base.size(ts::TimeSeries) = (ts.n+1,)
Base.size(ts::TimeSeries, d) = d == 1 ? size(ts) : 0

Base.eachindex(::IndexCartesian, ts::TimeSeries) = CartesianIndices(axes(ts))
Base.eachindex(::IndexLinear, ts::TimeSeries) = axes(ts, 1)

Base.firstindex(ts::TimeSeries) = 0
Base.firstindex(ts::TimeSeries,d) = d == 1 ? 0 : 1

Base.lastindex(ts::TimeSeries) = ts.n
Base.lastindex(ts::TimeSeries,d) = d == 1 ? lastindex(ts) : 1

@inline Base.axes(ts::TimeSeries) = (0:ts.n,)
@inline Base.axes(ts::TimeSeries, d) = d == 1 ? (axes(parent(ts))[d] .- 1) : (1:1)

Base.strides(ts::TimeSeries) = strides(1)
Base.stride(ts::TimeSeries, d) = strides(ts)[d]


@inline function Base.setindex!(ts::TimeSeries, t, i::Int)
    @boundscheck checkbounds(ts.t, i.+1)
    @inbounds setindex!(ts.t, t, i.+1)
end

@inline function Base.getindex(ts::TimeSeries, i::Int)
    @boundscheck checkbounds(ts.t, i.+1)
    @inbounds t = getindex(ts.t, i.+1)
    return t
end

function compute_timeseries!(ts::TimeSeries{T}, t₀::T) where {T}
    ts[0] = t₀
    for i in Base.OneTo(ts.n)
        ts[i] = ts[0] + i * ts.step * ts.Δt
    end
end
