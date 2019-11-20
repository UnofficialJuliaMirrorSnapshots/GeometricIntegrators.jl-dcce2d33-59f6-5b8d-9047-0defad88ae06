
using GeometricIntegrators.Config
using GeometricIntegrators.Integrators
using GeometricIntegrators.Solvers
using GeometricIntegrators.Tableaus
using GeometricIntegrators.TestProblems.LotkaVolterra
using GeometricIntegrators.Utils
using Test

set_config(:nls_atol, 8eps())
set_config(:nls_rtol, 2eps())
set_config(:nls_solver, QuasiNewtonSolver)
set_config(:jacobian_autodiff, true)

using GeometricIntegrators.TestProblems.LotkaVolterra: Δt, nt

idae = lotka_volterra_2d_idae()
pdae = lotka_volterra_2d_pdae()

int  = IntegratorFIRK(lotka_volterra_2d_ode(), getTableauGLRK(8), Δt)
sol  = integrate(int, nt)
refx = sol.q[:,end]


@testset "$(rpad("VPARK integrators",80))" begin

    dint = Integrator(idae, getTableauSymplecticProjection(:pglrk1ps, getCoefficientsGLRK(1), getCoefficientsGLRK(1)), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6

    dint = Integrator(idae, getTableauSymplecticProjection(:pglrk2ps, getCoefficientsGLRK(2), getCoefficientsGLRK(2)), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-11

    dint = Integrator(idae, getTableauGLRKpSymplectic(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6

    dint = Integrator(idae, getTableauGLRKpSymplectic(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-11

    dint = Integrator(idae, getTableauLobIIIAIIIB2pSymplectic(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-6

    dint = Integrator(idae, getTableauLobIIIAIIIB3pSymplectic(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 8E-5

end


@testset "$(rpad("VSPARK integrators",80))" begin
    ### VSPARK Integrators ###

    dint = IntegratorVSPARK(idae, getTableauSPARKGLRK(1), Δt)
    # dsol = integrate(dint, nt)
    # TODO
    # println(rel_err(dsol.q, refx))
    # @test rel_err(dsol.q, refx) < 1E-6


    ### VSPARKprimary Integrators ###

    dint = Integrator(idae, getTableauVSPARKGLRKpMidpoint(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6

    dint = Integrator(idae, getTableauVSPARKGLRKpMidpoint(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-11

    dint = Integrator(idae, getTableauVSPARKGLRKpSymplectic(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6

    dint = Integrator(idae, getTableauVSPARKGLRKpSymplectic(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-11

    dint = Integrator(idae, getTableauVSPARKGLRKpSymmetric(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6

    dint = Integrator(idae, getTableauVSPARKGLRKpSymmetric(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-11

    dint = IntegratorVSPARKprimary(idae, getTableauVSPARKLobIIIAIIIB2pSymmetric(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-6

    dint = IntegratorVSPARKprimary(idae, getTableauVSPARKLobIIIAIIIB3pSymmetric(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 8E-5

end


@testset "$(rpad("HPARK integrators",80))" begin

    dint = Integrator(pdae, getTableauHPARK(:hpark_glrk1, getCoefficientsGLRK(1), getCoefficientsGLRK(1)), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-6

    dint = Integrator(pdae, getTableauHPARK(:hpark_glrk2, getCoefficientsGLRK(2), getCoefficientsGLRK(2)), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 8E-7

    dint = Integrator(pdae, getTableauHPARKGLRK(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-6

    dint = Integrator(pdae, getTableauHPARKGLRK(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 8E-7

    dint = Integrator(pdae, getTableauHPARKLobIIIAIIIB2(), Δt)
    # dsol = integrate(dint, nt)
    # TODO
    # println(rel_err(dsol.q, refx))
    # @test rel_err(dsol.q, refx) < 2E-2

    dint = Integrator(pdae, getTableauHPARKLobIIIAIIIB3(), Δt)
    # dsol = integrate(dint, nt)
    # TODO
    # println(rel_err(dsol.q, refx))
    # @test rel_err(dsol.q, refx) < 8E-2

end


@testset "$(rpad("HSPARK integrators",80))" begin
    ### HSPARK Integrators ###

    dint = IntegratorHSPARK(pdae, getTableauSPARKGLRK(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 1E-6


    ### HSPARKprimary Integrators ###

    dint = Integrator(pdae, getTableauHSPARKGLRKpSymmetric(1), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-1

    dint = Integrator(pdae, getTableauHSPARKGLRKpSymmetric(2), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 4E-6

    dint = Integrator(pdae, getTableauHSPARKLobIIIAIIIB2pSymmetric(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 2E-1

    dint = Integrator(pdae, getTableauHSPARKLobIIIAIIIB3pSymmetric(), Δt)
    dsol = integrate(dint, nt)

    # println(rel_err(dsol.q, refx))
    @test rel_err(dsol.q, refx) < 4E-6
end
