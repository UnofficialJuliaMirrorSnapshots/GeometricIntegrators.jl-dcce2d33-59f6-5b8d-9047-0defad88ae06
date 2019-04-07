@doc raw"""
`TableauVPRK`: Tableau of a Variational Partitioned Runge-Kutta method
```math
\begin{align*}
P_{n,i} &= \dfrac{\partial L}{\partial v} (Q_{n,i}, V_{n,i}) , &
Q_{n,i} &= q_{n} + h \sum \limits_{j=1}^{s} a_{ij} \, V_{n,j} , &
q_{n+1} &= q_{n} + h \sum \limits_{i=1}^{s} b_{i} \, V_{n,i} , \\
F_{n,i} &= \dfrac{\partial L}{\partial q} (Q_{n,i}, V_{n,i}) , &
P_{n,i} &= p_{n} + h \sum \limits_{i=1}^{s} \bar{a}_{ij} \, F_{n,j} - d_i \lambda , &
p_{n+1} &= p_{n} + h \sum \limits_{i=1}^{s} \bar{b}_{i} \, F_{n,i} , \\
&&
0 &= \sum \limits_{i=1}^{s} d_i V_i , &&
\end{align*}
```
satisfying the symplecticity conditions
```math
\begin{align*}
b_{i} \bar{a}_{ij} + b_{j} a_{ji} &= b_{i} b_{j} , &
\bar{b}_i &= b_i .
\end{align*}
```
"""
struct TableauVPRK{T} <: AbstractTableauPRK{T}
    @HeaderTableau

    q::CoefficientsRK{T}
    p::CoefficientsRK{T}

    R∞::Int

    d::Vector{T}

    function TableauVPRK{T}(name, o, q, p, R∞, d) where {T}
        @assert q.s == p.s == length(d)
        new(name, o, q.s, q, p, R∞, d)
    end

    function TableauVPRK{T}(name, o, q, p, R∞) where {T}
        @assert q.s == p.s
        new(name, o, q.s, q, p, R∞)
    end
end

function TableauVPRK(name::Symbol, order::Int, q::CoefficientsRK{T}, p::CoefficientsRK{T}, R∞::Int, d::Vector{T}) where {T}
    TableauVPRK{T}(name, order, q, p, R∞, d)
end

function TableauVPRK(name::Symbol, order::Int, q::CoefficientsRK{T}, p::CoefficientsRK{T}, R∞::Int) where {T}
    TableauVPRK{T}(name, order, q, p, R∞)
end

function TableauVPRK(name::Symbol, order::Int, q::CoefficientsRK{T}, R∞::Int, d::Vector{T}) where {T}
    TableauVPRK{T}(name, order, q, get_symplectic_conjugate_coefficients(q), R∞, d)
end

function TableauVPRK(name::Symbol, order::Int, q::CoefficientsRK{T}, R∞::Int) where {T}
    TableauVPRK{T}(name, order, q, get_symplectic_conjugate_coefficients(q), R∞)
end


"Parameters for right-hand side function of variational partitioned Runge-Kutta methods."
mutable struct ParametersVPRK{DT, TT, ET <: IODE{DT,TT}, D, S} <: AbstractParametersVPRK{DT,TT,ET,D,S}
    equ::ET
    tab::TableauVPRK{TT}
    Δt::TT

    t::TT
    q::Vector{DT}
    p::Vector{DT}
end

function ParametersVPRK(equ::ET, tab::TableauVPRK{TT}, Δt::TT) where {DT, TT, ET <: IODE{DT,TT}}
    q = zeros(DT, equ.d)
    p = zeros(DT, equ.d)

    ParametersVPRK{DT, TT, ET, equ.d, tab.s}(equ, tab, Δt, 0, q, p)
end


"Compute stages of variational partitioned Runge-Kutta methods."
@generated function function_stages!(x::Vector{ST}, b::Vector{ST},
                params::ParametersVPRK{DT,TT,ET,D,S}
            ) where {ST,DT,TT,ET,D,S}

    cache = NonlinearFunctionCacheVPRK{ST}(D, S)

    quote
        @assert length(x) == length(b)

        compute_stages!(x, $cache.Q, $cache.V, $cache.P, $cache.F, params)
        compute_rhs_vprk!(b, $cache.P, $cache.F, params)
        compute_rhs_vprk_correction!(b, $cache.V, params)
    end
end


"Variational partitioned Runge-Kutta integrator."
struct IntegratorVPRK{DT, TT, PT <: ParametersVPRK{DT,TT},
                              ST <: NonlinearSolver{DT},
                              IT <: InitialGuessPODE{DT,TT}} <: AbstractIntegratorVPRK{DT,TT}

    params::PT
    solver::ST
    iguess::IT

    cache::NonlinearFunctionCacheVPRK{DT}

    q::Vector{Vector{TwicePrecision{DT}}}
    p::Vector{Vector{TwicePrecision{DT}}}
end

function IntegratorVPRK(equation::ET, tableau::TableauVPRK{TT}, Δt::TT) where {DT, TT, ET <: IODE{DT,TT}}
    D = equation.d
    M = equation.n
    S = tableau.s

    # create params
    params = ParametersVPRK(equation, tableau, Δt)

    # create nonlinear solver
    solver = create_nonlinear_solver(DT, D*S, params)

    # create initial guess
    iguess = InitialGuessPODE(get_config(:ig_interpolation), equation, Δt)

    # create cache for internal stage vectors and update vectors
    cache = NonlinearFunctionCacheVPRK{DT}(D,S)

    # create solution vectors
    q = create_solution_vector(DT, D, M)
    p = create_solution_vector(DT, D, M)

    # create integrator
    IntegratorVPRK{DT, TT, typeof(params), typeof(solver), typeof(iguess)}(
                params, solver, iguess, cache, q, p)
end


IntegratorVPRKpNone = IntegratorVPRK


function initialize!(int::AbstractIntegratorVPRK{DT,TT}, sol::SolutionPDAE, m::Int) where {DT,TT}
    @assert m ≥ 1
    @assert m ≤ sol.ni

    # copy initial conditions from solution
    get_initial_conditions!(sol, int.q[m], int.p[m], m)

    # initialise initial guess
    initialize!(int.iguess, m, sol.t[0], int.q[m], int.p[m])
end


function initial_guess!(int::IntegratorVPRK, m::Int)
    for i in 1:int.params.tab.s
        evaluate!(int.iguess, m, int.cache.y, int.cache.z, int.cache.v, int.params.tab.q.c[i], int.params.tab.p.c[i])
        for k in 1:int.params.equ.d
            int.solver.x[int.params.equ.d*(i-1)+k] = int.cache.v[k]
        end
    end
end

"Integrate ODE with variational partitioned Runge-Kutta integrator."
function integrate_step!(int::IntegratorVPRK{DT,TT}, sol::SolutionPDAE{DT,TT}, m::Int, n::Int) where {DT,TT}
    # check if m and n are compatible with solution dimensions
    check_solution_dimension_asserts(sol, m, n)

    # set time for nonlinear solver
    int.params.t  = sol.t[0] + (n-1)*int.params.Δt
    int.params.q .= int.q[m]
    int.params.p .= int.p[m]

    # compute initial guess
    initial_guess!(int, m)

    # call nonlinear solver
    solve!(int.solver)

    # print solver status
    print_solver_status(int.solver.status, int.solver.params, n)

    # check if solution contains NaNs or error bounds are violated
    check_solver_status(int.solver.status, int.solver.params, n)

    # compute vector fields at internal stages
    compute_stages!(int.solver.x, int.cache.Q, int.cache.V, int.cache.P, int.cache.F, int.params)

    # compute final update
    update_solution!(int.q[m], int.cache.V, int.params.tab.q.b, int.params.tab.q.b̂, int.params.Δt)
    update_solution!(int.p[m], int.cache.F, int.params.tab.p.b, int.params.tab.p.b̂, int.params.Δt)

    # copy solution to initial guess for next time step
    update!(int.iguess, m, sol.t[0] + n*int.params.Δt, int.q[m], int.p[m])

    # take care of periodic solutions
    cut_periodic_solution!(int.q[m], int.params.equ.periodicity)

    # copy to solution
    copy_solution!(sol, int.q[m], int.p[m], n, m)
end
