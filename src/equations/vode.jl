@doc raw"""
`VODE`: Variational Ordinary Differential Equation

Defines an implicit initial value problem
```math
\begin{align*}
\dot{q} (t) &= v(t) , &
q(t_{0}) &= q_{0} , \\
\dot{p} (t) &= f(t, q(t), v(t)) , &
p(t_{0}) &= p_{0} , \\
p(t) &= α(t, q(t), v(t))
\end{align*}
```
with vector field ``f``, the momentum defined by ``p``, initial conditions ``(q_{0}, p_{0})`` and the solution
``(q,p)`` taking values in ``\mathbb{R}^{d} \times \mathbb{R}^{d}``.
This is a special case of a differential algebraic equation with dynamical
variables ``(q,p)`` and algebraic variable ``v``.

### Fields

* `d`: dimension of dynamical variables ``q`` and ``p`` as well as the vector fields ``f`` and ``p``
* `α`: function determining the momentum
* `f`: function computing the vector field
* `g`: function determining the projection, given by ∇α(q)λ
* `v`: function computing an initial guess for the velocity field (optional)
* `t₀`: initial time (optional)
* `q₀`: initial condition for `q`
* `p₀`: initial condition for `p`
* `λ₀`: initial condition for `λ`

The functions `α` and `f` must have the interface
```julia
    function α(t, q, v, p)
        p[1] = ...
        p[2] = ...
        ...
    end
```
and
```julia
    function f(t, q, v, f)
        f[1] = ...
        f[2] = ...
        ...
    end
```
where `t` is the current time, `q` is the current solution vector, `v` is the
current velocity and `f` and `p` are the vectors which hold the result of
evaluating the functions ``f`` and ``α`` on `t`, `q` and `v`.
The funtions `g` and `v` are specified by
```julia
    function g(t, q, λ, g)
        g[1] = ...
        g[2] = ...
        ...
    end
```
and
```julia
    function v(t, q, p, v)
        v[1] = ...
        v[2] = ...
        ...
    end
```
"""
struct VODE{dType <: Number, tType <: Number, αType <: Function, fType <: Function, gType <: Function, vType <: Function, ωType <: Function, dHType <: Function, N} <: Equation{dType, tType}
    d::Int
    m::Int
    n::Int
    α::αType
    f::fType
    g::gType
    v::vType
    ω::ωType
    dH::dHType
    t₀::tType
    q₀::Array{dType, N}
    p₀::Array{dType, N}
    λ₀::Array{dType, N}
    periodicity::Vector{dType}

    function VODE{dType,tType,αType,fType,gType,vType,ωType,dHType,N}(d, n, α, f, g, v, ω, dH, t₀, q₀, p₀; periodicity=[]) where {dType <: Number, tType <: Number, αType <: Function, fType <: Function, gType <: Function, vType <: Function, ωType <: Function, dHType <: Function, N}
        @assert d == size(q₀,1) == size(p₀,1)
        @assert n == size(q₀,2) == size(p₀,2)
        @assert dType == eltype(q₀) == eltype(p₀)
        @assert ndims(q₀) == ndims(p₀) == N ∈ (1,2)

        λ₀ = zero(q₀)

        if !(length(periodicity) == d)
            periodicity = zeros(dType, d)
        end

        new(d, d, n, α, f, g, v, ω, dH, t₀, q₀, p₀, λ₀, periodicity)
    end
end

function VODE(α::ΑT, f::FT, g::GT, v::VT, ω::ΩT, dH::HT, t₀::TT, q₀::DenseArray{DT}, p₀::DenseArray{DT}; periodicity=[]) where {DT,TT,ΑT,FT,GT,VT,ΩT,HT}
    @assert size(q₀) == size(p₀)
    VODE{DT, TT, ΑT, FT, GT, VT, ΩT, HT, ndims(q₀)}(size(q₀, 1), size(q₀, 2), α, f, g, v, ω, dH, t₀, q₀, p₀, periodicity=periodicity)
end

function VODE(α::Function, f::Function, g::Function, ω::Function, dH::Function, t₀::Number, q₀::DenseArray, p₀::DenseArray; periodicity=[])
    VODE(α, f, g, function_v_dummy, ω, dH, t₀, q₀, p₀, periodicity=periodicity)
end

function VODE(α::Function, f::Function, g::Function, v::Function, ω::Function, dH::Function, q₀::DenseArray, p₀::DenseArray; periodicity=[])
    VODE(α, f, g, v, ω, dH, zero(Float64), q₀, p₀, periodicity=periodicity)
end

function VODE(α::Function, f::Function, g::Function, ω::Function, dH::Function, q₀::DenseArray, p₀::DenseArray; periodicity=[])
    VODE(α, f, g, function_v_dummy, ω, dH, zero(Float64), q₀, p₀, periodicity=periodicity)
end

Base.hash(ode::VODE, h::UInt) = hash(ode.d, hash(ode.n, hash(ode.α, hash(ode.f, hash(ode.g, hash(ode.v, hash(ode.ω, hash(ode.t₀, hash(ode.q₀, hash(ode.p₀, hash(ode.λ₀, hash(ode.periodicity, h))))))))))))
Base.:(==)(ode1::VODE, ode2::VODE) = (
                                ode1.d == ode2.d
                             && ode1.n == ode2.n
                             && ode1.α == ode2.α
                             && ode1.f == ode2.f
                             && ode1.g == ode2.g
                             && ode1.v == ode2.v
                             && ode1.ω == ode2.ω
                             && ode1.t₀ == ode2.t₀
                             && ode1.q₀ == ode2.q₀
                             && ode1.p₀ == ode2.p₀
                             && ode1.λ₀ == ode2.λ₀
                             && ode1.periodicity == ode2.periodicity)
