module SolutionTests

    export test_deterministic_solutions, test_stochastic_solutions

    using GeometricIntegrators
    using GeometricIntegrators.Solutions: createHDF5
    using HDF5: HDF5File
    using Test

    using ..OscillatorTest: oscillator_ode
    using ..KuboOscillatorTest

    include("test_functions.jl")

    ntime = 10
    Δt    = .1

    ode   = oscillator_ode()
    dim   = ode.d

    t0    = 0.
    q0    = rand(dim)
    p0    = q0.^2
    λ0    = [0.]

    t1    = 1.
    n1    = 5
    q1    = rand(dim, n1)
    p1    = q1.^2
    λ1    = zeros(1, n1)

    tq    = zero(q0)
    q2    = rand(dim, n1)

    testfile = "test.hdf5"


    function test_deterministic_solutions()
        @testset "$(rpad("Deterministic Solutions",80))" begin
            ### Test SolutionODE ###

            sol = Solution(ode, Δt, ntime)
            @test typeof(sol) <: SolutionODE

            sol0 = Solution(similar(ode, q0), Δt, ntime)
            @test typeof(sol0) <: SolutionODE

            sol1 = Solution(similar(ode, q1), Δt, ntime)
            @test typeof(sol1) <: SolutionODE

            @test sol != sol0
            @test sol != sol1

            set_initial_conditions!(sol, t0, q0)
            get_initial_conditions!(sol, tq, 1)

            # @test sol != sol0
            @test tq == q0

            set_initial_conditions!(sol1, similar(ode, t1, q2))
            get_initial_conditions!(sol1, tq, 1)
            @test tq == q2[:,1]

            # test hdf5 in- and output
            h5 = createHDF5(sol, testfile)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)

            h5 = createHDF5(sol, testfile; overwrite=false)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)
            rm(testfile)

            write_to_hdf5(sol, testfile)
            @test isfile(testfile)
            rm(testfile)

            create_hdf5(sol, testfile)
            write_to_hdf5(sol)
            close(sol)

            sol2 = SolutionODE(testfile)
            @test sol != sol2
            rm(testfile)

            # test nsave and nwrite parameters
            sol = Solution(ode, Δt, 20, 2)
            @test sol.nt == 10

            sol = Solution(ode, Δt, 20, 2, 10)
            @test sol.nt == 5


            ### Test SolutionPODE ###

            pode = PODE(fq, fp, q0, p0)
            psol = Solution(pode, Δt, ntime)

            pode0 = PODE(fq, fp, q0, p0)
            psol0 = Solution(pode0, Δt, ntime)
            @test typeof(psol0) <: SolutionPODE

            pode1 = PODE(fq, fp, q1, p1)
            psol1 = Solution(pode1, Δt, ntime)
            @test typeof(psol1) <: SolutionPODE

            @test pode == pode0
            @test pode != pode1

            # test hdf5 in- and output
            create_hdf5(psol, "test.hdf5")
            write_to_hdf5(psol)
            close(psol)

            psol2 = SolutionPODE("test.hdf5")
            @test psol != psol2
            rm("test.hdf5")


            ### Test SolutionDAE ###

            dae = DAE(fx, gx, fϕ, q0, λ0)
            sol = Solution(dae, Δt, ntime)
            @test typeof(sol) <: SolutionDAE

            dae = DAE(fx, gx, fϕ, q1, λ1)
            sol = Solution(dae, Δt, ntime)
            @test typeof(sol) <: SolutionDAE

            # test hdf5 in- and output
            create_hdf5(sol, "test.hdf5")
            write_to_hdf5(sol)
            close(sol)

            sol2 = SolutionDAE("test.hdf5")
            @test sol != sol2
            rm("test.hdf5")


            ### Test SolutionPDAE ###

            pdae = PDAE(fq, fp, gq, gp, gϕ, q0, p0, λ0)
            psol = Solution(pdae, Δt, ntime)
            @test typeof(psol) <: SSolutionPDAE

            pdae = PDAE(fq, fp, gq, gp, gϕ, q1, p1, λ1)
            psol = Solution(pdae, Δt, ntime)
            @test typeof(psol) <: SSolutionPDAE

            # test hdf5 in- and output
            create_hdf5(psol, "test.hdf5")
            write_to_hdf5(psol)
            close(psol)

            psol2 = SSolutionPDAE("test.hdf5")
            @test psol != psol2
            rm("test.hdf5")
        end
    end


    function test_stochastic_solutions()
        @testset "$(rpad("Stochastic solutions",80))" begin

            ### Test SolutionSDE ###
            sde  = kubo_oscillator_sde_1()
            ssol = Solution(sde, Δt, ntime)
            @test typeof(ssol) <: SolutionSDE

            # test hdf5 in- and output
            h5 = createHDF5(ssol, testfile)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)

            h5 = createHDF5(ssol, testfile, overwrite=false)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)
            rm(testfile)


            ### Test SolutionPSDE ###
            psde  = kubo_oscillator_psde_1()
            ssol = Solution(psde, Δt, ntime)
            @test typeof(ssol) <: SolutionPSDE

            # test hdf5 in- and output
            h5 = createHDF5(ssol, testfile)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)

            h5 = createHDF5(ssol, testfile, overwrite=false)
            @test typeof(h5) == HDF5File
            close(h5)
            @test isfile(testfile)
            rm(testfile)


            ### Test SolutionSPSDE ###
            spsde  = kubo_oscillator_spsde_1()
            ssol = Solution(spsde, Δt, ntime)
            @test typeof(ssol) <: SolutionPSDE
        end
    end
end

using .SolutionTests
test_deterministic_solutions()
test_stochastic_solutions()
