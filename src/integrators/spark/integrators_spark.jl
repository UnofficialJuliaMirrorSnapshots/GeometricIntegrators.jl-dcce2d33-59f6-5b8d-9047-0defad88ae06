
"Holds the tableau of an Specialised Partitioned Additive Runge-Kutta method."
struct TableauSPARK{T} <: AbstractTableau{T}
    name::Symbol
    o::Int
    s::Int
    r::Int
    ρ::Int

    q::CoefficientsARK{T}
    p::CoefficientsARK{T}

    q̃::CoefficientsPRK{T}
    p̃::CoefficientsPRK{T}

    λ::CoefficientsMRK{T}

    ω::Matrix{T}
    d::Vector{T}

    function TableauSPARK{T}(name, o, s, r, ρ, q, p, q̃, p̃, λ, ω, d) where {T}
        @assert isa(name, Symbol)
        @assert isa(s, Integer)
        @assert isa(r, Integer)
        @assert isa(ρ, Integer)
        @assert isa(o, Integer)

        @assert s > 0 "Number of stages s must be > 0"
        @assert r > 0 "Number of stages r must be > 0"
        @assert ρ > 0 && ρ ≤ r

        @assert s==q.s==p.s==q̃.s==p̃.s==length(d)
        @assert r==q.r==p.r==q̃.r==p̃.r==λ.r
        @assert ρ==size(ω, 1)
        @assert r==size(ω, 2)

        new(name, o, s, r, ρ, q, p, q̃, p̃, λ, ω, d)
    end

    function TableauSPARK{T}(name, o, s, r, ρ, q, p, q̃, p̃, λ, ω) where {T}
        @assert isa(name, Symbol)
        @assert isa(s, Integer)
        @assert isa(r, Integer)
        @assert isa(ρ, Integer)
        @assert isa(o, Integer)

        @assert s > 0 "Number of stages s must be > 0"
        @assert r > 0 "Number of stages r must be > 0"
        @assert ρ > 0 && ρ ≤ r

        @assert s==q.s==p.s==q̃.s==p̃.s
        @assert r==q.r==p.r==q̃.r==p̃.r==λ.r
        @assert ρ==size(ω, 1)
        @assert r==size(ω, 2)

        new(name, o, s, r, ρ, q, p, q̃, p̃, λ, ω)
    end
end

function TableauSPARK(name::Symbol, order::Int,
                         a_q::Matrix{T}, a_p::Matrix{T},
                         α_q::Matrix{T}, α_p::Matrix{T},
                         a_q̃::Matrix{T}, a_p̃::Matrix{T},
                         α_q̃::Matrix{T}, α_p̃::Matrix{T},
                         b_q::Vector{T}, b_p::Vector{T},
                         β_q::Vector{T}, β_p::Vector{T},
                         c_q::Vector{T}, c_p::Vector{T},
                         c_λ::Vector{T}, d_λ::Vector{T},
                         ω_λ::Matrix{T}, d::Vector{T}) where {T <: Real}

    s = length(c_q)
    r = length(c_λ)
    ρ = size(ω_λ, 1)

    @assert s > 0 "Number of stages s must be > 0"
    @assert r > 0 "Number of stages r must be > 0"

    @assert s==size(a_q,1)==size(a_q,2)==length(b_q)==length(c_q)
    @assert s==size(a_p,1)==size(a_p,2)==length(b_p)==length(c_p)
    @assert s==size(α_q,1)==size(α_p,1)
    @assert r==size(α_q,2)==size(α_p,2)
    @assert s==length(d)
    @assert r==length(c_λ)==length(d_λ)
    @assert r==size(a_q̃,1)==size(a_p̃,1)
    @assert s==size(a_q̃,2)==size(a_p̃,2)
    @assert r==size(α_q̃,1)==size(α_q̃,2)==length(β_q)
    @assert r==size(α_p̃,1)==size(α_p̃,2)==length(β_p)

    q = CoefficientsARK{T}(name, order, s, r, a_q, b_q, c_q, α_q, β_q)
    p = CoefficientsARK{T}(name, order, s, r, a_p, b_p, c_p, α_p, β_p)
    q̃ = CoefficientsPRK{T}(name, order, s, r, a_q̃, c_λ, α_q̃)
    p̃ = CoefficientsPRK{T}(name, order, s, r, a_p̃, c_λ, α_p̃)
    λ = CoefficientsMRK{T}(name, r, d_λ, c_λ)

    TableauSPARK{T}(name, order, s, r, ρ, q, p, q̃, p̃, λ, ω_λ, d)
end


function TableauSPARK(name::Symbol, order::Int,
                         a_q::Matrix{T}, a_p::Matrix{T},
                         α_q::Matrix{T}, α_p::Matrix{T},
                         a_q̃::Matrix{T}, a_p̃::Matrix{T},
                         α_q̃::Matrix{T}, α_p̃::Matrix{T},
                         b_q::Vector{T}, b_p::Vector{T},
                         β_q::Vector{T}, β_p::Vector{T},
                         c_q::Vector{T}, c_p::Vector{T},
                         c_λ::Vector{T}, d_λ::Vector{T},
                         ω_λ::Matrix{T}) where {T <: Real}

    s = length(c_q)
    r = length(c_λ)
    ρ = size(ω_λ, 1)

    @assert s > 0 "Number of stages s must be > 0"
    @assert r > 0 "Number of stages r must be > 0"

    @assert s==size(a_q,1)==size(a_q,2)==length(b_q)==length(c_q)
    @assert s==size(a_p,1)==size(a_p,2)==length(b_p)==length(c_p)
    @assert s==size(α_q,1)==size(α_p,1)
    @assert r==size(α_q,2)==size(α_p,2)
    @assert r==length(c_λ)==length(d_λ)
    @assert r==size(a_q̃,1)==size(a_p̃,1)
    @assert s==size(a_q̃,2)==size(a_p̃,2)
    @assert r==size(α_q̃,1)==size(α_q̃,2)==length(β_q)
    @assert r==size(α_p̃,1)==size(α_p̃,2)==length(β_p)

    q = CoefficientsARK{T}(name, order, s, r, a_q, b_q, c_q, α_q, β_q)
    p = CoefficientsARK{T}(name, order, s, r, a_p, b_p, c_p, α_p, β_p)
    q̃ = CoefficientsPRK{T}(name, order, s, r, a_q̃, c_λ, α_q̃)
    p̃ = CoefficientsPRK{T}(name, order, s, r, a_p̃, c_λ, α_p̃)
    λ = CoefficientsMRK{T}(name, r, d_λ, c_λ)

    TableauSPARK{T}(name, order, s, r, ρ, q, p, q̃, p̃, λ, ω_λ)
end

# TODO function readTableauSPARKFromFile(dir::AbstractString, name::AbstractString)


"Parameters for right-hand side function of Specialised Partitioned Additive Runge-Kutta methods."
mutable struct ParametersSPARK{DT,TT,FT,PT,UT,GT,ϕT} <: Parameters{DT,TT}
    f_f::FT
    f_p::PT
    f_u::UT
    f_g::GT
    f_ϕ::ϕT

    Δt::TT

    d::Int
    s::Int
    r::Int
    ρ::Int

    t_q::CoefficientsARK{TT}
    t_p::CoefficientsARK{TT}
    t_q̃::CoefficientsPRK{TT}
    t_p̃::CoefficientsPRK{TT}
    t_λ::CoefficientsMRK{TT}
    ω_λ::Matrix{TT}
    d_v::Vector{TT}

    t::TT

    q::Vector{DT}
    v::Vector{DT}
    p::Vector{DT}
    λ::Vector{DT}
    μ::Vector{DT}

    y::Vector{DT}
    z::Vector{DT}

    Qi::Matrix{DT}
    Pi::Matrix{DT}
    Vi::Matrix{DT}
    Λi::Matrix{DT}
    Fi::Matrix{DT}
    Yi::Matrix{DT}
    Zi::Matrix{DT}
    Φi::Matrix{DT}

    Qp::Matrix{DT}
    Pp::Matrix{DT}
    Vp::Matrix{DT}
    Up::Matrix{DT}
    Gp::Matrix{DT}
    Yp::Matrix{DT}
    Zp::Matrix{DT}
    Φp::Matrix{DT}

    Λρ::Matrix{DT}
    Φρ::Matrix{DT}

    Qt::Vector{DT}
    Pt::Vector{DT}
    Λt::Vector{DT}
    Vt::Vector{DT}
    Ft::Vector{DT}
    Ut::Vector{DT}
    Gt::Vector{DT}
    Φt::Vector{DT}

    function ParametersSPARK{DT,TT,FT,PT,UT,GT,ϕT}(f_f, f_p, f_u, f_g, f_ϕ, Δt, d, s, r, ρ, t_q, t_p, t_q̃, t_p̃, t_λ, ω_λ, d_v) where {DT,TT,FT,PT,UT,GT,ϕT}
        # create solution vectors
        q = zeros(DT,d)
        v = zeros(DT,d)
        p = zeros(DT,d)
        λ = zeros(DT,d)
        μ = zeros(DT,d)

        y = zeros(DT,d)
        z = zeros(DT,d)

        # create internal stage vectors
        Qi = zeros(DT,d,s)
        Pi = zeros(DT,d,s)
        Vi = zeros(DT,d,s)
        Λi = zeros(DT,d,s)
        Fi = zeros(DT,d,s)
        Yi = zeros(DT,d,s)
        Zi = zeros(DT,d,s)
        Φi = zeros(DT,d,s)

        Qp = zeros(DT,d,r)
        Pp = zeros(DT,d,r)
        Vp = zeros(DT,d,r)
        Up = zeros(DT,d,r)
        Gp = zeros(DT,d,r)
        Yp = zeros(DT,d,r)
        Zp = zeros(DT,d,r)
        Φp = zeros(DT,d,r)

        Λρ = zeros(DT,d,ρ)
        Φρ = zeros(DT,d,ρ)

        # create temporary vectors
        Qt = zeros(DT,d)
        Pt = zeros(DT,d)
        Λt = zeros(DT,d)
        Vt = zeros(DT,d)
        Ft = zeros(DT,d)
        Ut = zeros(DT,d)
        Gt = zeros(DT,d)
        Φt = zeros(DT,d)

        new(f_f, f_p, f_u, f_g, f_ϕ,
            Δt, d, s, r, ρ,
            t_q, t_p, t_q̃, t_p̃, t_λ, ω_λ, d_v,
            0, q, v, p, λ, μ, y, z,
            Qi, Pi, Vi, Λi, Fi, Yi, Zi, Φi,
            Qp, Pp, Vp, Up, Gp, Yp, Zp, Φp,
            Λρ, Φρ,
            Qt, Pt, Λt, Vt, Ft, Ut, Gt, Φt)
    end
end

"Compute stages of variational special partitioned additive Runge-Kutta methods."
function function_stages!(y::Vector{DT}, b::Vector{DT}, params::ParametersSPARK{DT,TT,FT,PT,UT,GT,ϕT}) where {DT,TT,FT,PT,UT,GT,ϕT}
    local offset::Int
    local tpᵢ::TT
    local tλᵢ::TT

    for i in 1:params.s
        for k in 1:params.d
            # copy y to Y, Z
            offset = 3*(params.d*(i-1)+k-1)
            params.Yi[k,i] = y[offset+1]
            params.Zi[k,i] = y[offset+2]
            params.Vi[k,i] = y[offset+3]

            # compute Q and P
            params.Qi[k,i] = params.q[k] + params.Δt * params.Yi[k,i]
            params.Pi[k,i] = params.p[k] + params.Δt * params.Zi[k,i]
        end

        # compute f(X)
        tpᵢ = params.t + params.Δt * params.t_p.c[i]

        simd_copy_xy_first!(params.Qt, params.Qi, i)
        # simd_copy_xy_first!(params.Pt, params.Pi, i)
        simd_copy_xy_first!(params.Vt, params.Vi, i)
        params.f_f(tpᵢ, params.Qt, params.Vt, params.Ft)
        params.f_p(tpᵢ, params.Qt, params.Vt, params.Pt)
        # params.f_ϕ(tpᵢ, params.Qt, params.Pt, params.Φt)
        simd_copy_yx_first!(params.Ft, params.Fi, i)
        # simd_copy_yx_first!(params.Φt, params.Φi, i)
        simd_copy_yx_first!(params.Pt, params.Φi, i)
    end

    params.Φi .-= params.Pi

    for i in 1:params.r
        for k in 1:params.d
            # copy y to Y and Z
            offset = 3*params.d*params.s+3*(params.d*(i-1)+k-1)
            params.Yp[k,i] = y[offset+1]
            params.Zp[k,i] = y[offset+2]
            params.Vp[k,i] = y[offset+3]

            # compute Q and V
            params.Qp[k,i] = params.q[k] + params.Δt * params.Yp[k,i]
            params.Pp[k,i] = params.p[k] + params.Δt * params.Zp[k,i]
        end

        # compute f(X)
        tλᵢ = params.t + params.Δt * params.t_λ.c[i]

        simd_copy_xy_first!(params.Qt, params.Qp, i)
        simd_copy_xy_first!(params.Pt, params.Pp, i)
        simd_copy_xy_first!(params.Vt, params.Vp, i)
        params.f_u(tλᵢ, params.Qt, params.Pt, params.Vt, params.Ut)
        params.f_g(tλᵢ, params.Qt, params.Pt, params.Vt, params.Gt)
        params.f_ϕ(tλᵢ, params.Qt, params.Pt, params.Φt)
        simd_copy_yx_first!(params.Ut, params.Up, i)
        simd_copy_yx_first!(params.Gt, params.Gp, i)
        simd_copy_yx_first!(params.Φt, params.Φp, i)
    end

    for i in 1:params.ρ
        offset = 3*params.d*params.s+3*params.d*params.r+params.d*(i-1)
        for k in 1:params.d
            params.Λρ[k,i] = y[offset+k]
        end
    end

    if length(params.d_v) > 0
        offset = 3*params.d*params.s+3*params.d*params.r+params.d*params.ρ
        for k in 1:params.d
            params.μ[k] = y[offset+k]
        end
    end

    # compute b = - [(Y-AV-AU), (Z-AF-AG), Φ]
    for i in 1:params.s
        for k in 1:params.d
            offset = 3*(params.d*(i-1)+k-1)
            b[offset+1] = - params.Yi[k,i]
            b[offset+2] = - params.Zi[k,i]
            b[offset+3] = params.Φi[k,i]
            for j in 1:params.s
                b[offset+1] += params.t_q.a[i,j] * params.Vi[k,j]
                b[offset+2] += params.t_p.a[i,j] * params.Fi[k,j]
            end
            for j in 1:params.r
                b[offset+1] += params.t_q.α[i,j] * params.Up[k,j]
                b[offset+2] += params.t_p.α[i,j] * params.Gp[k,j]
            end
        end
    end

    # compute b = - [(Y-AV-AU), (Z-AF-AG), Φ]
    for i in 1:params.r
        for k in 1:params.d
            offset = 3*params.d*params.s+3*(params.d*(i-1)+k-1)
            b[offset+1] = - params.Yp[k,i]
            b[offset+2] = - params.Zp[k,i]
            b[offset+3] = - params.Vp[k,i]
            for j in 1:params.s
                b[offset+1] += params.t_q̃.a[i,j] * params.Vi[k,j]
                b[offset+2] += params.t_p̃.a[i,j] * params.Fi[k,j]
            end
            for j in 1:params.r
                b[offset+1] += params.t_q̃.α[i,j] * params.Up[k,j]
                b[offset+2] += params.t_p̃.α[i,j] * params.Gp[k,j]
            end
            for j in 1:params.ρ
                b[offset+3] += params.ω_λ[j,i] * params.Λρ[k,j]
            end
        end
    end

    for i in 1:params.ρ
        for k in 1:params.d
            offset = 3*params.d*params.s+3*params.d*params.r+params.d*(i-1)+k
            b[offset] = 0
            for j in 1:params.r
                b[offset] -= params.ω_λ[i,j] * params.Φp[k,j]
            end
        end
    end

    if length(params.d_v) > 0
        for i in 1:params.s
            for k in 1:params.d
                b[3*(params.d*(i-1)+k-1)+3] -= params.d_v[i] * params.μ[k]
            end
        end

        offset = 3*params.d*params.s+3*params.d*params.r+params.d*params.ρ
        for k in 1:params.d
            b[offset+k] = 0
            for i in 1:params.s
                b[offset+k] -= params.Vi[k,i] * params.d_v[i]
            end
        end
    end
end


"Variational special partitioned additive Runge-Kutta integrator."
mutable struct IntegratorSPARK{DT, TT, FT, PT, UT, GT, ϕT, VT, SPT, ST, IT} <: Integrator{DT, TT}
    equation::IDAE{DT,TT,FT,PT,UT,GT,ϕT}
    tableau::TableauSPARK{TT}
    Δt::TT

    params::SPT
    solver::ST
    iguess::InitialGuessPODE{DT, TT, VT, FT, IT}

    q::Array{DT,1}
    v::Array{DT,1}
    p::Array{DT,1}
    λ::Array{DT,1}
    y::Array{DT,1}
    z::Array{DT,1}

    Q::Array{DT,2}
    P::Array{DT,2}
    V::Array{DT,2}
    F::Array{DT,2}
    Λ::Array{DT,2}
    U::Array{DT,2}
    G::Array{DT,2}
end

function IntegratorSPARK(equation::IDAE{DT,TT,FT,PT,UT,GT,ϕT,VT}, tableau::TableauSPARK{TT}, Δt::TT) where {DT,TT,FT,PT,UT,GT,ϕT,VT}
    D = equation.d
    S = tableau.s
    R = tableau.r
    ρ = tableau.ρ

    N = 3*D*S + 3*D*R + D*ρ

    if isdefined(tableau, :d)
        N += D
        d_v = tableau.d
    else
        d_v = DT[]
    end

    # create solution vector for internal stages / nonlinear solver
    z = zeros(DT, N)

    # create params
    params = ParametersSPARK{DT,TT,FT,PT,UT,GT,ϕT}(
                                                equation.f, equation.p, equation.u, equation.g, equation.ϕ,
                                                Δt, D, S, R, ρ,
                                                tableau.q, tableau.p, tableau.q̃, tableau.p̃, tableau.λ, tableau.ω, d_v)

    # create rhs function for nonlinear solver
    function_stages = (x,b) -> function_stages!(x, b, params)

    # create solver
    solver = get_config(:nls_solver)(z, function_stages)

    # create initial guess
    iguess = InitialGuessPODE(get_config(:ig_interpolation), equation, Δt)

    # create integrator
    IntegratorSPARK{DT, TT, FT, PT, UT, GT, ϕT, VT, typeof(params), typeof(solver), typeof(iguess.int)}(
                                        equation, tableau, Δt, params, solver, iguess,
                                        params.q, params.v, params.p, params.λ,
                                        params.y, params.z,
                                        params.Qi, params.Pi, params.Vi, params.Fi,
                                        params.Vp, params.Up, params.Gp)
end


function initialize!(int::IntegratorSPARK, sol::Union{SolutionPDAE, PSolutionPDAE}, m::Int)
    @assert m ≥ 1
    @assert m ≤ sol.ni

    # copy initial conditions from solution
    get_initial_conditions!(sol, int.q, int.p, int.λ, m)

    # initialise initial guess
    initialize!(int.iguess, m, sol.t[0], int.q, int.p)
end

"Integrate DAE with variational special partitioned additive Runge-Kutta integrator."
function integrate_step!(int::IntegratorSPARK{DT,TT,FT,PT,UT,GT,ϕT,VT}, sol::SolutionPDAE{DT,TT,N}, m::Int, n::Int) where {DT,TT,FT,PT,UT,GT,ϕT,VT,N}
    local offset::Int

    # set time for nonlinear solver
    int.params.t = sol.t[n]

    # copy previous solution to initial guess
    update!(int.iguess, sol.t[n], int.q, int.p)

    # compute initial guess
    for i in 1:int.tableau.s
        evaluate!(int.iguess, int.y, int.z, int.v, int.tableau.q.c[i], int.tableau.p.c[i])
        for k in 1:int.equation.d
            offset = 3*(int.equation.d*(i-1)+k-1)
            int.solver.x[offset+1] = (int.y[k] - int.q[k])/(int.Δt)
            int.solver.x[offset+2] = (int.z[k] - int.p[k])/(int.Δt)
            int.solver.x[offset+3] = int.v[k]
        end
    end

    for i in 1:int.tableau.r
        evaluate!(int.iguess, int.y, int.z, int.v, int.tableau.q̃.c[i], int.tableau.p̃.c[i])
        for k in 1:int.equation.d
            offset = 3*int.equation.d*int.tableau.s+3*(int.equation.d*(i-1)+k-1)
            int.solver.x[offset+1] = (int.y[k] - int.q[k])/(int.Δt)
            int.solver.x[offset+2] = (int.z[k] - int.p[k])/(int.Δt)
            int.solver.x[offset+3] = 0
        end
    end

    for i in 1:int.tableau.ρ
        offset = 3*int.equation.d*int.tableau.s+3*int.equation.d*int.tableau.r+int.equation.d*(i-1)
        for k in 1:int.equation.d
            int.solver.x[offset+k] = 0
            # for j in 1:int.tableau.r
            #     int.solver.x[offset+k] += 0
            # end
        end
    end

    if isdefined(int.tableau, :d)
        offset = 3*int.equation.d*int.tableau.s+3*int.equation.d*int.tableau.r+int.equation.d*int.tableau.ρ
        for k in 1:int.equation.d
            int.solver.x[offset+k] = 0
        end
    end

    # println("ig:  ", join([@sprintf "%8.4e" x for x in int.solver.x], ", "))

    # call nonlinear solver
    solve!(int.solver)

    # println("sol: ", join([@sprintf "%8.4e" x for x in int.solver.x], ", "))
    #
    # println(int.solver.status)
    # println()

    if !check_solver_status(int.solver.status, int.solver.params)
        println(int.solver.status)
    end

    # if isnan(int.solver.status.rₐ)
    #     break
    # end

    # compute final update
    simd_mult!(int.y, int.V, int.tableau.q.b)
    simd_mult!(int.z, int.F, int.tableau.p.b)
    int.q .+= int.Δt .* int.y
    int.p .+= int.Δt .* int.z
    simd_mult!(int.y, int.U, int.tableau.q.β)
    simd_mult!(int.z, int.G, int.tableau.p.β)
    int.q .+= int.Δt .* int.y
    int.p .+= int.Δt .* int.z
    simd_mult!(int.λ, int.Λ, int.tableau.λ.b)

    # copy to solution
    copy_solution!(sol, int.q, int.p, int.λ, n, m)
end
