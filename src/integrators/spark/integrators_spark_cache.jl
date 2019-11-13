"""
Cache of a Specialised Partitioned Additive Runge-Kutta integrator.

### Fields

* `n`: time step number
* `t`: time of current time step
* `t̅`: time of previous time step
* `q`: current solution of q
* `q̅`: previous solution of q
* `p`: current solution of p
* `p̅`: previous solution of p
* `v`: vector field of q
* `v̅`: vector field of q̅
* `f`: vector field of p
* `f̅`: vector field of p̅
* `q̃`: initial guess of q
* `p̃`: initial guess of p
* `ṽ`: initial guess of v
* `f̃`: initial guess of f
* `s̃`: holds shift due to periodicity of solution
* `Q`: internal stages of q
* `P`: internal stages of p
* `V`: internal stages of v
* `F`: internal stages of f
* `Y`: vector field of internal stages of q
* `Z`: vector field of internal stages of p
"""
mutable struct IntegratorCacheSPARK{ST,TT,D,S,R} <: IDAEIntegratorCache{ST,D}
    n::Int
    t::TT
    t̅::TT

    q::Vector{ST}
    q̅::Vector{ST}
    p::Vector{ST}
    p̅::Vector{ST}
    λ::Vector{ST}
    λ̅::Vector{ST}
    μ::Vector{ST}
    μ̅::Vector{ST}

    qₑᵣᵣ::Vector{ST}
    pₑᵣᵣ::Vector{ST}

    v::Vector{ST}
    v̅::Vector{ST}
    f::Vector{ST}
    f̅::Vector{ST}
    u::Vector{ST}
    u̅::Vector{ST}
    g::Vector{ST}
    g̅::Vector{ST}
    ϕ::Vector{ST}
    ϕ̅::Vector{ST}

    q̃::Vector{ST}
    p̃::Vector{ST}
    ṽ::Vector{ST}
    f̃::Vector{ST}
    ϕ̃::Vector{ST}
    s̃::Vector{ST}

    Qi::Vector{Vector{ST}}
    Pi::Vector{Vector{ST}}
    Vi::Vector{Vector{ST}}
    Fi::Vector{Vector{ST}}
    Yi::Vector{Vector{ST}}
    Zi::Vector{Vector{ST}}
    Φi::Vector{Vector{ST}}

    Qp::Vector{Vector{ST}}
    Pp::Vector{Vector{ST}}
    Λp::Vector{Vector{ST}}
    Up::Vector{Vector{ST}}
    Gp::Vector{Vector{ST}}
    Yp::Vector{Vector{ST}}
    Zp::Vector{Vector{ST}}
    Φp::Vector{Vector{ST}}

    function IntegratorCacheSPARK{ST,TT,D,S,R}() where {ST,TT,D,S,R}
        q = zeros(ST,D)
        q̅ = zeros(ST,D)
        p = zeros(ST,D)
        p̅ = zeros(ST,D)
        λ = zeros(ST,D)
        λ̅ = zeros(ST,D)
        μ = zeros(ST,D)
        μ̅ = zeros(ST,D)

        # create error vectors
        qₑᵣᵣ = zeros(ST,D)
        pₑᵣᵣ = zeros(ST,D)

        # create update vectors
        v = zeros(ST,D)
        v̅ = zeros(ST,D)
        f = zeros(ST,D)
        f̅ = zeros(ST,D)
        u = zeros(ST,D)
        u̅ = zeros(ST,D)
        g = zeros(ST,D)
        g̅ = zeros(ST,D)
        ϕ = zeros(ST,D)
        ϕ̅ = zeros(ST,D)

        # create temporary vectors
        q̃ = zeros(ST,D)
        p̃ = zeros(ST,D)
        ṽ = zeros(ST,D)
        f̃ = zeros(ST,D)
        ϕ̃ = zeros(ST,D)
        s̃ = zeros(ST,D)

        # create internal stage vectors
        Qi = create_internal_stage_vector(ST, D, S)
        Pi = create_internal_stage_vector(ST, D, S)
        Vi = create_internal_stage_vector(ST, D, S)
        Fi = create_internal_stage_vector(ST, D, S)
        Yi = create_internal_stage_vector(ST, D, S)
        Zi = create_internal_stage_vector(ST, D, S)
        Φi = create_internal_stage_vector(ST, D, S)

        Qp = create_internal_stage_vector(ST, D, R)
        Pp = create_internal_stage_vector(ST, D, R)
        Λp = create_internal_stage_vector(ST, D, R)
        Up = create_internal_stage_vector(ST, D, R)
        Gp = create_internal_stage_vector(ST, D, R)
        Yp = create_internal_stage_vector(ST, D, R)
        Zp = create_internal_stage_vector(ST, D, R)
        Φp = create_internal_stage_vector(ST, D, R)

        new(0, zero(TT), zero(TT), q, q̅, p, p̅, λ, λ̅, μ, μ̅,
                                   qₑᵣᵣ, pₑᵣᵣ,
                                   v, v̅, f, f̅, u, u̅, g, g̅, ϕ, ϕ̅,
                                   q̃, p̃, ṽ, f̃, ϕ̃, s̃,
                                   Qi, Pi, Vi, Fi, Yi, Zi, Φi,
                                   Qp, Pp, Λp, Up, Gp, Yp, Zp, Φp)
    end
end

function CommonFunctions.reset!(cache::IntegratorCacheSPARK, Δt)
    cache.t̅  = cache.t
    cache.q̅ .= cache.q
    cache.p̅ .= cache.p
    cache.λ̅ .= cache.λ
    cache.v̅ .= cache.v
    cache.f̅ .= cache.f
    cache.u̅ .= cache.u
    cache.g̅ .= cache.g
    cache.ϕ̅ .= cache.ϕ
    cache.t += Δt
    cache.n += 1
end