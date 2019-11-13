module Equations

    export Equation, ODE, IODE, PODE, SODE, VODE, DAE, HDAE, IDAE, PDAE
    export SDE, PSDE, SPSDE

    include("equations/equations.jl")

    include("equations/ode.jl")
    include("equations/iode.jl")
    include("equations/pode.jl")
    include("equations/sode.jl")
    include("equations/vode.jl")
    include("equations/dae.jl")
    include("equations/hdae.jl")
    include("equations/idae.jl")
    include("equations/pdae.jl")
    include("equations/sde.jl")
    include("equations/psde.jl")
    include("equations/spsde.jl")

end
