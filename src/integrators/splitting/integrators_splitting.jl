
abstract type AbstractTableauSplitting{T <: Real} <: AbstractTableau{T} end


"Tableau for non-symmetric splitting methods."
struct TableauSplittingNS{T} <: AbstractTableauSplitting{T}
    @HeaderTableau

    a::Vector{T}
    b::Vector{T}

    function TableauSplittingNS{T}(name, o, s, a, b) where {T}
        @assert s == length(a) == length(b)
        new(name, o, s, a, b)
    end
end

function TableauSplittingNS(name, o, a::Vector{T}, b::Vector{T}) where {T}
    TableauSplittingNS{T}(name, o, length(a), a, b)
end


"Tableau for symmetric splitting methods with general stages."
struct TableauSplittingGS{T} <: AbstractTableauSplitting{T}
    @HeaderTableau

    a::Vector{T}
    b::Vector{T}

    function TableauSplittingGS{T}(name, o, s, a, b) where {T}
        @assert s == length(a) == length(b)
        new(name, o, s, a, b)
    end
end

function TableauSplittingGS(name, o, a::Vector{T}, b::Vector{T}) where {T}
    TableauSplittingGS{T}(name, o, length(a), a, b)
end


"Tableau for symmetric splitting methods with symmetric stages."
struct TableauSplittingSS{T} <: AbstractTableauSplitting{T}
    @HeaderTableau

    a::Vector{T}

    function TableauSplittingSS{T}(name, o, s, a) where {T}
        @assert s == length(a)
        new(name, o, s, a)
    end
end

function TableauSplittingSS(name, o, a::Vector{T}) where {T}
    TableauSplittingSS{T}(name, o, length(a), a)
end



"Splitting integrator."
struct IntegratorSplitting{DT, TT, VT, ST <: AbstractTableauSplitting, FT, CT, N} <: DeterministicIntegrator{DT,TT}
    equation::SODE{DT,TT,VT,N}
    tableau::ST
    f::FT
    c::CT
    Δt::TT

    q::Array{DT,1}
    qₑᵣᵣ::Array{DT,1}
    v::Array{DT,1}

    function IntegratorSplitting{DT,TT,VT,ST,FT,CT,N}(equation::SODE, tableau::ST, f::FT, c::CT, Δt) where {DT,TT,VT,ST,FT,CT,N}
        @assert length(f) == length(c)
        D = equation.d
        new(equation, tableau, f, c, Δt, zeros(DT,D), zeros(DT,D), zeros(DT,D))
    end
end


function IntegratorSplitting(equation::SODE{DT,TT,VT,N}, tableau::ST, f::Vector{Int}, c::Vector{TT}, Δt::TT) where {DT, TT, VT, ST <: AbstractTableauSplitting, N}
    ft = Tuple(f)
    ct = Tuple(c)
    IntegratorSplitting{DT,TT,VT,ST,typeof(ft),typeof(ct),N}(equation, tableau, ft, ct, Δt)
end


function get_splitting_coefficients(r, a::Vector{TT}, b::Vector{TT}) where {TT}
    @assert length(a) == length(b)

    s = length(a)
    f = zeros(Int, 2r*s)
    c = zeros(TT,  2r*s)

    for i in 1:s
        for j in 1:r
            f[(2i-2)*r+j] = j
            c[(2i-2)*r+j] = a[i]
        end
        for j in 1:r
            f[(2i-1)*r+j] = r-j+1
            c[(2i-1)*r+j] = b[i]
        end
    end

    return f, c
end


"Construct splitting integrator for non-symmetric splitting tableau with general stages."
function IntegratorSplitting(equation::SODE{DT,TT,VT}, tableau::ST, Δt::TT) where {DT, TT, VT, ST <: TableauSplittingNS{TT}}

    # basic method: Lie composition
    # \varphi_{\tau,A} = \varphi_{\tau,v_1} \circ \varphi_{\tau,v_2} \circ \hdots \varphi_{\tau,v_{r-1}} \circ \varphi_{\tau,v_r}
    # \varphi_{\tau,B} = \varphi_{\tau,v_r} \circ \varphi_{\tau,v_{r-1}} \circ \hdots \varphi_{\tau,v_2} \circ \varphi_{\tau,v_1}

    # integrator:
    # \varphi_{NS} = \varphi_{b_s \tau, B} \circ \varphi_{a_s \tau, A} \circ \hdots \circ \varphi_{b_1 \tau, B} \circ \varphi_{a_1 \tau, A}

    f, c = get_splitting_coefficients(length(equation.v), tableau.a, tableau.b)

    # R = length(equation.v)
    # S = tableau.s
    #
    # f = zeros(Int, 2R*S)
    # c = zeros(TT,  2R*S)
    #
    # for i in 1:S
    #     for j in 1:R
    #         f[(2i-2)*R+j] = j
    #         c[(2i-2)*R+j] = tableau.a[i]
    #     end
    #     for j in 1:R
    #         f[(2i-1)*R+j] = R-j+1
    #         c[(2i-1)*R+j] = tableau.b[i]
    #     end
    # end

    IntegratorSplitting(equation, tableau, f, c, Δt)
end


"Construct splitting integrator for symmetric splitting tableau with general stages."
function IntegratorSplitting(equation::SODE{DT,TT,VT}, tableau::ST, Δt::TT) where {DT, TT, VT, ST <: TableauSplittingGS{TT}}

    # basic method: Lie composition
    # \varphi_{\tau,A} = \varphi_{\tau,v_1} \circ \varphi_{\tau,v_2} \circ \hdots \varphi_{\tau,v_{r-1}} \circ \varphi_{\tau,v_r}
    # \varphi_{\tau,B} = \varphi_{\tau,v_r} \circ \varphi_{\tau,v_{r-1}} \circ \hdots \varphi_{\tau,v_2} \circ \varphi_{\tau,v_1}

    # integrator:
    # \varphi_{GS} = \varphi_{a_1 \tau, A} \circ \varphi_{b_1 \tau, B} \circ \hdots \circ \varphi_{b_1 \tau, B} \circ \varphi_{a_1 \tau, A}

    f, c = get_splitting_coefficients(length(equation.v), tableau.a, tableau.b)

    # R = length(equation.v)
    # S = tableau.s
    #
    # f = zeros(Int, 2R*S)
    # c = zeros(TT,  2R*S)
    #
    # for i in 1:S
    #     for j in 1:R
    #         f[(2i-2)*R+j] = j
    #         c[(2i-2)*R+j] = tableau.a[i]
    #     end
    #     for j in R:-1:1
    #         f[(2i-1)*R+j] = R-j+1
    #         c[(2i-1)*R+j] = tableau.b[i]
    #     end
    # end

    IntegratorSplitting(equation, tableau, vcat(f, f[end:-1:1]), vcat(c, c[end:-1:1]), Δt)
end


"Construct splitting integrator for symmetric splitting tableau with symmetric stages."
function IntegratorSplitting(equation::SODE{DT,TT,VT}, tableau::ST, Δt::TT) where {DT, TT, VT, ST <: TableauSplittingSS{TT}}

    # basic method: symmetric Strang composition
    # \varphi_{\tau,A} = \varphi_{\tau/2,v_1} \circ \varphi_{\tau/2,v_2} \circ \hdots \varphi_{\tau/2,v_{r-1}} \circ \varphi_{\tau/2,v_r}
    #              \circ \varphi_{\tau/2,v_r} \circ \varphi_{\tau/2,v_{r-1}} \circ \hdots \varphi_{\tau/2,v_2} \circ \varphi_{\tau/2,v_1}

    # integrator:
    # \varphi_{SS} = \varphi_{a_1 \tau, A} \circ \varphi_{a_2 \tau, A} \hdots \circ \varphi_{a_s \tau, A} \circ \hdots \circ \varphi_{a_2 \tau, A} \circ \varphi_{a_1 \tau, A}

    r = length(equation.v)
    a = vcat(tableau.a, tableau.a[end-1:-1:1]) ./ 2
    s = length(a)

    f = zeros(Int, 2r*s)
    c = zeros(TT,  2r*s)

    for i in 1:s
        for j in 1:r
            f[(2i-2)*r+j] = j
            c[(2i-2)*r+j] = a[i]
            f[(2i-1)*r+j] = r-j+1
            c[(2i-1)*r+j] = a[i]
        end
    end

    IntegratorSplitting(equation, tableau, f, c, Δt)
end


equation(int::IntegratorSplitting) = int.equation
timestep(int::IntegratorSplitting) = int.Δt


"Explicit Runge-Kutta integrator cache."
mutable struct IntegratorCacheSplitting{DT,TT,D} <: ODEIntegratorCache{DT,D}
    n::Int
    t::TT
    t̅::TT
    q::Vector{TwicePrecision{DT}}
    q̅::Vector{TwicePrecision{DT}}
    v::Vector{DT}
    s̃::Vector{DT}

    function IntegratorCacheSplitting{DT,TT,D}() where {DT,TT,D}
        q = zeros(TwicePrecision{DT}, D)
        q̅ = zeros(TwicePrecision{DT}, D)
        v = zeros(DT, D)
        s̃ = zeros(DT, D)
        new(0, zero(TT), zero(TT), q, q̅, v, s̃)
    end
end

function create_integrator_cache(int::IntegratorSplitting{DT,TT}) where {DT,TT}
    IntegratorCacheSplitting{DT, TT, ndims(equation(int))}()
end

function CommonFunctions.reset!(cache::IntegratorCacheSplitting{DT,TT}, Δt::TT) where {DT,TT}
    cache.t̅  = cache.t
    cache.q̅ .= cache.q
    cache.t += Δt
    cache.n += 1
end


function CommonFunctions.set_solution!(cache::IntegratorCacheSplitting, sol, n=0)
    t, q = sol
    cache.n  = n
    cache.t  = t
    cache.q .= q
end


"Integrate ODE with splitting integrator."
function integrate_step!(int::IntegratorSplitting{DT,TT,FT}, cache::IntegratorCacheSplitting{DT,TT}) where {DT,TT,FT}
    local tᵢ::TT

    # reset cache
    reset!(cache, int.Δt)

    # compute internal stages
    for i in eachindex(int.f, int.c)
        if int.c[i] ≠ zero(TT)
            tᵢ = cache.t̅ + int.Δt * int.c[i]
            int.equation.v[int.f[i]](tᵢ, cache.q, cache.v, int.c[i] * int.Δt)
            cache.q .= cache.v
        end
    end

    # take care of periodic solutions
    cut_periodic_solution!(cache, equation(int).periodicity)
end
