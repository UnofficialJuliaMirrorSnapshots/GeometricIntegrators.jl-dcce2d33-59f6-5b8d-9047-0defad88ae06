module GeometricIntegrators

    using Reexport

    include("Utils.jl")
    using .Utils

    include("Config.jl")
    @reexport using .Config
    include("CommonFunctions.jl")
    @reexport using .CommonFunctions
    include("Equations.jl")
    @reexport using .Equations
    include("Solutions.jl")
    @reexport using .Solutions
    include("Interpolation.jl")
    @reexport using .Interpolation
    include("Solvers.jl")
    @reexport using .Solvers
    include("BasisFunctions.jl")
    @reexport using .BasisFunctions
    include("Quadratures.jl")
    @reexport using .Quadratures
    include("Discontinuities.jl")
    @reexport using .Discontinuities
    include("Integrators.jl")
    @reexport using .Integrators
    include("Simulations.jl")
    @reexport using .Simulations
    include("Tableaus.jl")
    @reexport using .Tableaus

    include("TestProblems.jl")
    export TestProblems


    function __init__()
        add_config(:verbosity, 1)
    end

end
