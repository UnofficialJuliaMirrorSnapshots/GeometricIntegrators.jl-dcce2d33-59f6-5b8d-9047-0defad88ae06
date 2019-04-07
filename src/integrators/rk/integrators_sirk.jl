"""
 Holds the tableau of a stochastic implicit Runge-Kutta method.
 qdrift holds the RK coefficients for the drift part,
 and qdiff holds the RK coefficients for the diffusion part of the SDE.
"""
struct TableauSIRK{T} <: AbstractTableauIRK{T}
    name::Symbol
    s::Int
    qdrift::CoefficientsRK{T}
    qdiff::CoefficientsRK{T}

    # Order of the tableau is not included, because unlike in the deterministic
    # setting, it depends on the properties of the noise (e.g., the dimension of
    # the Wiener process and the commutativity properties of the diffusion matrix)
    #
    # Orders stored in qdrift and qdiff are understood as the classical orders of these methods.


    function TableauSIRK{T}(name, s, qdrift, qdiff) where {T}
        # THE COMMENTED OUT PART WAS FOR TableauFIRK. MAY IMPLEMENT SOMETHING
        # SIMILAR FOR TableauSIRK LATER.

        # if (q.s > 1 && istrilstrict(q.a)) || (q.s==1 && q.a[1,1] == 0)
        #     warn("Initializing TableauFIRK with explicit tableau ", q.name, ".\n",
        #          "You might want to use TableauERK instead.")
        # elseif q.s > 1 && istril(q.a)
        #     warn("Initializing TableauFIRK with diagonally implicit tableau ", q.name, ".\n",
        #          "You might want to use TableauDIRK instead.")
        # end

        @assert s == qdrift.s == qdiff.s

        new(name, s, qdrift, qdiff)
    end
end

function TableauSIRK(name::Symbol, qdrift::CoefficientsRK{T}, qdiff::CoefficientsRK{T}) where {T}
    TableauSIRK{T}(name, qdrift.s, qdrift, qdiff)
end

function TableauSIRK(name::Symbol, order_drift::Int, a_drift::Matrix{T}, b_drift::Vector{T}, c_drift::Vector{T}, order_diff::Int, a_diff::Matrix{T}, b_diff::Vector{T}, c_diff::Vector{T}) where {T}
    TableauSIRK{T}(name, length(c_drift), CoefficientsRK(name, order_drift, a_drift, b_drift, c_drift), CoefficientsRK(name, order_diff, a_diff, b_diff, c_diff))
end

# TODO function readTableauSIRKFromFile(dir::AbstractString, name::AbstractString)


"""
Parameters for right-hand side function of implicit Runge-Kutta methods.
   A - if positive, the upper bound of the Wiener process increments; if A=0.0, no truncation
"""
mutable struct ParametersSIRK{DT, TT, ET <: SDE{DT,TT}, D, M, S} <: Parameters{DT,TT}
    equ::ET
    tab::TableauSIRK{TT}
    Δt::TT
    ΔW::Vector{DT}
    ΔZ::Vector{DT}
    A::DT

    t::TT
    q::Vector{DT}
end

function ParametersSIRK(equ::ET, tab::TableauSIRK{TT}, Δt::TT, ΔW::Vector{DT}, ΔZ::Vector{DT}, A::DT) where {DT, TT, ET <: SDE{DT,TT}}
    @assert equ.m == length(ΔW) == length(ΔZ)
    ParametersSIRK{DT, TT, ET, equ.d, equ.m, tab.s}(equ, tab, Δt, ΔW, ΔZ, A, 0, zeros(DT, equ.d))
end


"""
Structure for holding the internal stages Q, the values of the drift vector
and the diffusion matrix evaluated at the internal stages V=v(Q), B=B(Q),
and the increments Y = Δt*a_drift*v(Q) + a_diff*B(Q)*ΔW
"""
struct NonlinearFunctionCacheSIRK{DT}
    Q::Vector{Vector{DT}}
    V::Vector{Vector{DT}}
    B::Vector{Matrix{DT}}
    Y::Vector{Vector{DT}}

    v::Vector{DT}
    b::Matrix{DT}
    y::Vector{DT}

    function NonlinearFunctionCacheSIRK{DT}(d, m, s) where {DT}

        # create internal stage vectors
        Q = create_internal_stage_vector(DT, d, s)
        V = create_internal_stage_vector(DT, d, s)
        B = create_internal_stage_vector(DT, d, m, s)
        Y = create_internal_stage_vector(DT, d, s)

        # create velocity and update vector
        v = zeros(DT,d)
        b = zeros(DT,d,m)
        y = zeros(DT,d)

        new(Q, V, B, Y, v, b, y)
    end
end

"""
Unpacks the data stored in x = (Y[1][1], Y[1][2], ... Y[1][D], Y[2][1], ...)
into Y::Vector{Vector}, calculates the internal stages Q, the values of the RHS
of the SDE ( v(Q) and B(Q) ), and assigns them to V and B.
Unlike for FIRK, here Y = Δt a v(Q) + ̃a B(Q) ΔW
"""
function compute_stages!(x::Vector{ST}, Q::Vector{Vector{ST}}, V::Vector{Vector{ST}}, B::Vector{Matrix{ST}}, Y::Vector{Vector{ST}},
                         params::ParametersSIRK{DT,TT,ET,D,M,S}) where {ST,DT,TT,ET,D,M,S}

    local tᵢ::TT

    @assert S == length(Q) == length(V) == length(B)


    # copy x to Y and calculate Q
    for i in eachindex(Q)
        @assert D == size(B[i],1) == length(Q[i]) == length(V[i])
        @assert M == size(B[i],2)
        for k in eachindex(Q[i])
            Y[i][k] = x[D*(i-1)+k]
        end
        Q[i] .= params.q .+ Y[i]
    end

    # compute VQ = v(Q) and BQ=B(Q)
    for i in eachindex(Q,V,B)
        tᵢ = params.t + params.Δt * params.tab.qdrift.c[i]
        # calculates v(t,Q[i]) and assigns to the i-th column of V
        params.equ.v(tᵢ, Q[i], V[i])
        # calculates B(t,Q[i]) and assigns to the matrix B[i]
        params.equ.B(tᵢ, Q[i], B[i])
    end
end

"Compute stages of stochastic implicit Runge-Kutta methods."
@generated function function_stages!(x::Vector{ST}, b::Vector{ST}, params::ParametersSIRK{DT,TT,ET,D,M,S}) where {ST,DT,TT,ET,D,M,S}

    cache = NonlinearFunctionCacheSIRK{ST}(D, M, S)

    quote
        compute_stages!(x, $cache.Q, $cache.V, $cache.B, $cache.Y, params)

        local y1::ST
        local y2::ST

        # compute b = - (Y-AV)
        for i in 1:S
            for k in 1:D
                y1 = 0
                y2 = 0
                for j in 1:S
                    y1 += params.tab.qdrift.a[i,j] * $cache.V[j][k] * params.Δt + params.tab.qdiff.a[i,j] * dot($cache.B[j][k,:], params.ΔW)
                    y2 += params.tab.qdrift.â[i,j] * $cache.V[j][k] * params.Δt + params.tab.qdiff.â[i,j] * dot($cache.B[j][k,:], params.ΔW)
                end
                b[D*(i-1)+k] = - $cache.Y[i][k] + (y1 + y2)
            end
        end
    end
end


"Stochastic implicit Runge-Kutta integrator."
struct IntegratorSIRK{DT, TT, PT <: ParametersSIRK{DT,TT},
                              ST <: NonlinearSolver{DT}, N} <: StochasticIntegrator{DT,TT}
    params::PT
    solver::ST
    # InitialGuessSDE not implemented for SIRK
    #iguess::IT
    fcache::NonlinearFunctionCacheSIRK{DT}

    q::Matrix{Vector{TwicePrecision{DT}}}
end


# K - the integer in the bound A = √(2 K Δt |log Δt|) due to Milstein & Tretyakov; K=0 no truncation
function IntegratorSIRK(equation::SDE{DT,TT,VT,BT,N}, tableau::TableauSIRK{TT}, Δt::TT; K::Int=0) where {DT,TT,VT,BT,N}
    D = equation.d
    M = equation.m
    NS= equation.ns
    NI= equation.n
    S = tableau.s

    # create params
    K==0 ? A = 0.0 : A = sqrt( 2*K*Δt*abs(log(Δt)) )
    params = ParametersSIRK(equation, tableau, Δt, zeros(DT,M), zeros(DT,M), A)

    # create solver
    solver = create_nonlinear_solver(DT, D*S, params)

    # Not implementing InitialGuessSDE
    # create initial guess
    #iguess = InitialGuessODE(get_config(:ig_interpolation), equation, Δt)

    # create cache for internal stage vectors and update vectors
    fcache = NonlinearFunctionCacheSIRK{DT}(D, M, S)

    # create solution vectors
    q = create_solution_vector(DT, D, NS, NI)

    # create integrator
    IntegratorSIRK{DT, TT, typeof(params), typeof(solver), N}(params, solver, fcache, q)
end

equation(integrator::IntegratorSIRK) = integrator.params.equ
timestep(integrator::IntegratorSIRK) = integrator.params.Δt
tableau(integrator::IntegratorSIRK) = integrator.params.tab
dims(integrator::IntegratorSIRK) = integrator.params.equ.d
Base.eltype(integrator::IntegratorSIRK{DT, TT, PT, ST, N}) where {DT, TT, PT, ST, N} = DT


function initialize!(int::IntegratorSIRK{DT,TT}, sol::SolutionSDE, k::Int, m::Int) where {DT,TT}
    @assert m ≥ 1
    @assert m ≤ sol.ni
    @assert k ≥ 1
    @assert k ≤ sol.ns

    # copy the m-th initial condition for the k-th sample path
    get_initial_conditions!(sol, int.q[k,m], k, m)

    # Not implementing InitialGuessSDE
    # # initialise initial guess
    # initialize!(int.iguess, m, sol.t[0], int.q[m])
end

"""
This function computes initial guesses for Y and assigns them to int.solver.x
The prediction is calculated using an explicit integrator.
"""
function initial_guess!(int::IntegratorSIRK{DT,TT}) where {DT,TT}

    # NOT IMPLEMENTING InitialGuessSDE

    # SIMPLE SOLUTION
    # The simplest initial guess for Y is 0
    # int.solver.x .= zeros(eltype(int), int.params.tab.s*dims(int))

    # USING AN EXPLICIT INTEGRATOR TO COMPUTE AN INITIAL GUESS
    # Below we use the R2 method of Burrage & Burrage to calculate
    # the internal stages at the times c[1]...c[s].
    # This approach seems to give very good approximations if the time step
    # and magnitude of noise are not too large. If the noise intensity is too big,
    # one may have to perform a few iterations of the explicit method with a smaller
    # time step, use a higher-order explicit method (e.g. CL or G5), or use
    # the simple solution above.

    local tV1 = zeros(DT,int.params.equ.d)
    local tV2 = zeros(DT,int.params.equ.d)
    local tB1 = zeros(DT,int.params.equ.d, int.params.equ.m)
    local tB2 = zeros(DT,int.params.equ.d, int.params.equ.m)
    local Q   = zeros(DT,int.params.equ.d)
    local t2::TT
    local Δt_local::TT
    local ΔW_local = zeros(DT,int.params.equ.m)

    # When calling this function, int.params should contain the data:
    # int.params.q - the solution at the previous time step
    # int.params.t - the time of the previous step
    # int.params.ΔW- the increment of the Brownian motion for the current step

    #Evaluating the functions v and B at t,q - same for all stages
    int.params.equ.v(int.params.t, int.params.q, tV1)
    int.params.equ.B(int.params.t, int.params.q, tB1)

    for i in 1:int.params.tab.s

        Δt_local  = int.params.tab.qdrift.c[i]*int.params.Δt
        ΔW_local .= int.params.tab.qdrift.c[i]*int.params.ΔW

        Q = int.params.q + 2. / 3. * Δt_local * tV1 + 2. / 3. * tB1 * ΔW_local

        t2 = int.params.t + 2. / 3. *Δt_local

        int.params.equ.v(t2, Q, tV2)
        int.params.equ.B(t2, Q, tB2)

        #Calculating the Y's and assigning them to the array int.solver.x as initial guesses
        for j in 1:int.params.equ.d
            int.solver.x[(i-1)*int.params.equ.d+j] =  Δt_local*(1. / 4. * tV1[j] + 3. / 4. * tV2[j]) + dot( (1. / 4. * tB1[j,:] + 3. / 4. * tB2[j,:]), ΔW_local )
        end
    end

end


"""
Integrate SDE with a stochastic implicit Runge-Kutta integrator.
  Integrating the k-th sample path for the m-th initial condition
"""
function integrate_step!(int::IntegratorSIRK{DT,TT}, sol::SolutionSDE{DT,TT,NQ,NW}, k::Int, m::Int, n::Int) where {DT,TT,NQ,NW}

    @assert k ≥ 1
    @assert k ≤ sol.ns

    @assert m ≥ 1
    @assert m ≤ sol.ni

    @assert n ≥ 1
    @assert n ≤ sol.ntime


    # set time for nonlinear solver
    int.params.t  = sol.t[0] + (n-1)*int.params.Δt
    int.params.q .= int.q[k, m]


    # copy the increments of the Brownian Process
    if NW==1
        #1D Brownian motion, 1 sample path
        int.params.ΔW[1] = sol.W.ΔW[n-1]
        int.params.ΔZ[1] = sol.W.ΔZ[n-1]
    elseif NW==2
        #Multidimensional Brownian motion, 1 sample path
        int.params.ΔW .= sol.W.ΔW[n-1]
        int.params.ΔZ .= sol.W.ΔZ[n-1]
    elseif NW==3
        #1D or Multidimensional Brownian motion, k-th sample path
        int.params.ΔW .= sol.W.ΔW[n-1,k]
        int.params.ΔZ .= sol.W.ΔZ[n-1,k]
    end

    # truncate the increments ΔW with A
    if int.params.A>0
        for i in 1:length(int.params.ΔW)
            if int.params.ΔW[i]<-int.params.A
                int.params.ΔW[i] = -int.params.A
            elseif int.params.ΔW[i]>int.params.A
                int.params.ΔW[i] = int.params.A
            end
        end
    end

    # compute initial guess and assign to int.solver.x
    initial_guess!(int)

    # call nonlinear solver
    solve!(int.solver)

    # print solver status
    print_solver_status(int.solver.status, int.solver.params, n)

    # check if solution contains NaNs or error bounds are violated
    check_solver_status(int.solver.status, int.solver.params, n)

    # compute the drift vector field and the diffusion matrix at internal stages
    compute_stages!(int.solver.x, int.fcache.Q, int.fcache.V, int.fcache.B, int.fcache.Y, int.params)

    # compute final update
    update_solution!(int.q[k,m], int.fcache.V, int.fcache.B, int.params.tab.qdrift.b, int.params.tab.qdrift.b̂, int.params.tab.qdiff.b, int.params.tab.qdiff.b̂, int.params.Δt, int.params.ΔW)

    # # NOT IMPLEMENTING InitialGuessSDE
    # # # copy solution to initial guess
    # # update!(int.iguess, m, sol.t[0] + n*int.params.Δt, int.q[m])

    # take care of periodic solutions
    cut_periodic_solution!(int.q[k,m], int.params.equ.periodicity)

    # # copy to solution
    copy_solution!(sol, int.q[k,m], n, k, m)
end
