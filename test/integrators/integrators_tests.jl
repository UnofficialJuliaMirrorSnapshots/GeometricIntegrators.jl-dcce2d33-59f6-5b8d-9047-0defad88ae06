
using SafeTestsets

@safetestset "Runge-Kutta Integrators                                                         " begin include("rk_integrators_tests.jl") end
@safetestset "VPRK Integrators                                                                " begin include("vprk_integrators_tests.jl") end
@safetestset "SPARK Integrators                                                               " begin include("spark_integrators_tests.jl") end
@safetestset "Splitting Integrators                                                           " begin include("splitting_integrators_tests.jl") end
@safetestset "Galerkin Integrators                                                            " begin include("galerkin_integrators_tests.jl") end
@safetestset "Stochastic Integrators                                                          " begin include("stochastic_integrators_tests.jl") end
