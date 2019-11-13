@doc raw"""
`PSDE`: Stratonovich Partitioned Stochastic Differential Equation

Defines a partitioned stochastic differential initial value problem
```math
\begin{align*}
\dq (t) &= v(t, q(t)) \, dt + B(t, q(t)) \circ dW , & q(t_{0}) &= q_{0} ,
\dp (t) &= f(t, q(t)) \, dt + G(t, q(t)) \circ dW , & p(t_{0}) &= p_{0}
\end{align*}
```
with the drift vector fields ``v`` and ``f``, diffusion matrices ``B`` and ``G``,
initial conditions ``q_{0}`` and ``p_{0}``, the dynamical variables ``(q,p)`` taking
values in ``\mathbb{R}^{d} \times \mathbb{R}^{d}``, and the m-dimensional Wiener process W

### Fields

* `d`:  dimension of dynamical variable ``q`` and the vector field ``v``
* `m`:  dimension of the Wiener process
* `n`:  number of initial conditions
* `ns`: number of sample paths
* `v`:  function computing the drift vector field for the position variable q
* `f`:  function computing the drift vector field for the momentum variable p
* `B`:  function computing the d x m diffusion matrix for the position variable q
* `G`:  function computing the d x m diffusion matrix for the momentum variable p
* `t₀`: initial time
* `q₀`: initial condition for dynamical variable ``q`` (may be a random variable itself)
* `p₀`: initial condition for dynamical variable ``p`` (may be a random variable itself)


The functions `v`, `f`, 'B' and `G`, providing the drift vector fields and diffusion matrices, take four arguments,
`v(t, q, p, v)`, `f(t, q, p, f)`, `B(t, q, p,  B)` and `G(t, q, p, G)`, where `t` is the current time, `(q, p)` is the
current solution vector, and `v`, `f`, 'B' and `G` are the variables which hold the result
of evaluating the vector fields ``v``, ``f`` and the matrices ``B``, ``G`` on `t` and `(q,p)`.

### Example

```julia
    function v(λ, t, q, v)
        v[1] = λ*q[1]
        v[2] = λ*q[2]
    end

    function B(μ, t, q, B)
        B[1] = μ*q[1]
        B[2] = μ*q[2]
    end

    t₀ = 0.
    q₀ = [1., 1.]
    λ  = 2.
    μ  = 1.

    v_sde = (t, q, v) -> v(λ, t, q, v)
    B_sde = (t, q, B) -> B(μ, t, q, B)

    sde = SDE(v_sde, B_sde, t₀, q₀)
```
"""
struct PSDE{dType <: Number, tType <: Number, vType <: Function, fType <: Function, BType <: Function, GType <: Function, N} <: Equation{dType, tType}
    d::Int
    m::Int
    n::Int
    ns::Int
    v::vType
    f::fType
    B::BType
    G::GType
    t₀::tType
    q₀::Array{dType, N}           #Initial condition: N=1 - single deterministic, N=2 - single random or multiple deterministic, N=3 - multiple deterministic
    p₀::Array{dType, N}
    periodicity::Vector{dType}

    function PSDE{dType,tType,vType,fType,BType,GType,N}(d, m, n, ns, v, f, B, G, t₀, q₀, p₀; periodicity=[]) where {dType <: Number, tType <: Number, vType <: Function, fType <: Function, BType <: Function, GType <: Function, N}

        @assert dType == eltype(q₀) == eltype(p₀)
        @assert tType == typeof(t₀)
        @assert ndims(q₀) == ndims(p₀) == N
        @assert d == size(q₀,1) == size(p₀,1)

        if ns==1 && n==1
            # single sample path and single initial condition, therefore N=1
            @assert N == 1
        elseif ns>1 && n==1
            # single initial condition, but may be random (N=2) or deterministic (N=1)
            @assert N ∈ (1,2)
            if N==2
                @assert ns == size(q₀,2)
            end
        elseif ns==1 && n>1
            # multiple  deterministic initial conditions, so N=2
            @assert N == 2
            @assert n == size(q₀,2)
        elseif ns>1 && n>1
            # either multiple random initial conditions (N=3),
            # or multiple deterministic initial conditions (N=2)
            @assert N ∈ (2,3)

            if N==2
                @assert n == size(q₀,2)
            else
                @assert ns == size(q₀,2)
                @assert n == size(q₀,3)
            end
        end

        if !(length(periodicity) == d)
            periodicity = zeros(dType, d)
        end

        new(d, m, n, ns, v, f, B, G, t₀, q₀, p₀, periodicity)
    end
end


function PSDE(m::Int, ns::Int, v::VT, f::FT, B::BT, G::GT, t₀::TT, q₀::DenseArray{DT,1}, p₀::DenseArray{DT,1}; periodicity=[]) where {DT,TT,VT,FT,BT,GT}
    # A 1D array q₀ contains a single deterministic initial condition, so n=1, but we still need to specify
    # the number of sample paths ns
    @assert size(q₀) == size(p₀)
    PSDE{DT, TT, VT, FT, BT, GT, 1}(size(q₀, 1), m, 1, ns, v, f, B, G, t₀, q₀, p₀, periodicity=periodicity)
end


# A 2-dimensional matrix q0 can represent a single random initial condition with ns>1 and n=1,
# or a set of deterministic initial conditions with n>1 (for which we can have both ns=1 and ns>1)
# The function below assumes q0 to represent a single random initial condition (n=1, ns=size(q₀, 2))
function PSDE(m::Int, v::VT, f::FT, B::BT, G::GT, t₀::TT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}; periodicity=[]) where {DT,TT,VT,FT,BT,GT}
    PSDE{DT, TT, VT, FT, BT, GT, 2}(size(q₀, 1), m, 1, size(q₀, 2), v, f, B, G, t₀, q₀, p₀, periodicity=periodicity)
end

# On the other hand, the function below assumes q₀ represents multiple deterministic initial conditions
# (n=size(q₀, 2)), but these initial conditions may be run an arbitrary number ns of sample paths, so ns has to be explicitly specified
function PSDE(m::Int, ns::Int, v::VT, f::FT, B::BT, G::GT, t₀::TT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}; periodicity=[]) where {DT,TT,VT,FT,BT,GT}
    PSDE{DT, TT, VT, FT, BT, GT, 2}(size(q₀, 1), m, size(q₀, 2), ns, v, f, B, G, t₀, q₀, p₀, periodicity=periodicity)
end


function PSDE(m::Int, v::VT, f::FT, B::BT, G::GT, t₀::TT, q₀::DenseArray{DT,3}, p₀::DenseArray{DT,3}; periodicity=[]) where {DT,TT,VT,FT,BT,GT}
    @assert size(q₀) == size(p₀)
    PSDE{DT, TT, VT, FT, BT, GT, 3}(size(q₀, 1), m, size(q₀,3), size(q₀,2), v, f, B, G, t₀, q₀, p₀, periodicity=periodicity)
end


function PSDE(m::Int, ns::Int, v::VT, f::FT, B::BT, G::GT, q₀::DenseArray{DT,1}, p₀::DenseArray{DT,1}; periodicity=[]) where {DT,VT,FT,BT,GT}
    PSDE(m, ns, v, f, B, G, zero(DT), q₀, p₀, periodicity=periodicity)
end


# Assumes q0 represents a single random initial condition (n=1, ns=size(q₀, 2))
function PSDE(m::Int, v::VT, f::FT, B::BT, G::GT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}; periodicity=[]) where {DT,VT,FT,BT,GT}
    PSDE(m, v, f, B, G, zero(DT), q₀, p₀, periodicity=periodicity)
end


# Assumes q₀ represents multiple deterministic initial conditions (n=size(q₀, 2))
function PSDE(m::Int, ns::Int, v::VT, f::FT, B::BT, G::GT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}; periodicity=[]) where {DT,VT,FT,BT,GT}
    PSDE(m, ns, v, f, B, G, zero(DT), q₀, p₀, periodicity=periodicity)
end


function PSDE(m::Int, v::VT, f::FT, B::BT, G::GT, q₀::DenseArray{DT,3}, p₀::DenseArray{DT,3}; periodicity=[]) where {DT,VT,FT,BT,GT}
    PSDE(m, v, f, B, G, zero(DT), q₀, p₀, periodicity=periodicity)
end

Base.hash(sde::PSDE, h::UInt) = hash(sde.d, hash(sde.m, hash(sde.n, hash(sde.ns, hash(sde.v, hash(sde.f, hash(sde.B, hash(sde.G, hash(sde.t₀, hash(sde.q₀, hash(sde.p₀, hash(sde.periodicity, h))))))))))))

Base.:(==)(sde1::PSDE, sde2::PSDE) = (
                                sde1.d == sde2.d
                             && sde1.m == sde2.m
                             && sde1.n == sde2.n
                             && sde1.ns == sde2.ns
                             && sde1.v == sde2.v
                             && sde1.f == sde2.f
                             && sde1.B == sde2.B
                             && sde1.G == sde2.G
                             && sde1.t₀ == sde2.t₀
                             && sde1.q₀ == sde2.q₀
                             && sde1.p₀ == sde2.p₀
                             && sde1.periodicity == sde2.periodicity)

function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, q₀::DenseArray{DT,1}, p₀::DenseArray{DT,1}, ns::Int) where {DT, TT, VT, FT, BT, GT}
    similar(sde, sde.t₀, q₀, p₀, ns)
end

# Assumes q0 represents a single random initial condition (n=1, ns=size(q₀, 2))
function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}) where {DT, TT, VT, FT, BT, GT}
    similar(sde, sde.t₀, q₀, p₀)
end

# Assumes q₀ represents multiple deterministic initial conditions (n=size(q₀, 2))
function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}, ns::Int) where {DT, TT, VT, FT, BT, GT}
    similar(sde, sde.t₀, q₀, p₀, ns)
end

function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, q₀::DenseArray{DT,3}, p₀::DenseArray{DT,3}) where {DT, TT, VT, FT, BT, GT}
    similar(sde, sde.t₀, q₀, p₀)
end

function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, t₀::TT, q₀::DenseArray{DT,1}, p₀::DenseArray{DT,1}, ns::Int) where {DT, TT, VT, FT, BT, GT}
    @assert size(q₀) == size(p₀)
    @assert sde.d == size(q₀,1)
    PSDE(sde.m, ns, sde.v, sde.f, sde.B, sde.G, t₀, q₀, p₀, periodicity=sde.periodicity)
end

# Assumes q0 represents a single random initial condition (n=1, ns=size(q₀, 2))
function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, t₀::TT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}) where {DT, TT, VT, FT, BT, GT}
    @assert size(q₀) == size(p₀)
    @assert sde.d == size(q₀,1)
    PSDE(sde.m, sde.v, sde.f, sde.B, sde.G, t₀, q₀, p₀, periodicity=sde.periodicity)
end

# Assumes q₀ represents multiple deterministic initial conditions (n=size(q₀, 2))
function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, t₀::TT, q₀::DenseArray{DT,2}, p₀::DenseArray{DT,2}, ns::Int) where {DT, TT, VT, FT, BT, GT}
    @assert size(q₀) == size(p₀)
    @assert sde.d == size(q₀,1)
    PSDE(sde.m, ns, sde.v, sde.f, sde.B, sde.G, t₀, q₀, p₀, periodicity=sde.periodicity)
end

function Base.similar(sde::PSDE{DT,TT,VT,FT,BT,GT}, t₀::TT, q₀::DenseArray{DT,3}, p₀::DenseArray{DT,3}) where {DT, TT, VT, FT, BT, GT}
    @assert size(q₀) == size(p₀)
    @assert sde.d == size(q₀,1)
    PSDE(sde.m, sde.v, sde.f, sde.B, sde.G, t₀, q₀, p₀, periodicity=sde.periodicity)
end

Base.ndims(sde::PSDE) = sde.d
