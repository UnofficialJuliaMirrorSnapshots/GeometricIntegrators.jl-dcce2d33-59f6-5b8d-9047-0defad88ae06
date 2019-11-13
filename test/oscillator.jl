
module OscillatorTest

    using GeometricIntegrators.Equations

    export oscillator_ode, oscillator_pode, oscillator_sode,
           oscillator_iode, oscillator_idae, oscillator_pdae


    Δt  = 0.1
    nt  = 10

    k = 0.5
    ω = √k

    q₀=[0.5, 0.0]
    p₀=[0.0, 0.0]
    λ₀=[0.0, 0.0]

    A = sqrt(q₀[2]^2 / k + q₀[1]^2)
    ϕ = asin(q₀[1] / A)

    refq = A * sin(ω * Δt * nt + ϕ)
    refp = ω * Δt * nt * A * cos(ω * Δt * nt + ϕ)
    refx = [refq, refp]


    function oscillator_ode_v(t, x, v)
        v[1] = x[2]
        v[2] = -k*x[1]
        nothing
    end

    function oscillator_ode(x₀=q₀)
        ODE(oscillator_ode_v, x₀)
    end


    function oscillator_pode_v(t, q, p, v)
        v[1] = p[1]
        nothing
    end

    function oscillator_pode_f(t, q, p, f)
        f[1] = -k*q[1]
        nothing
    end

    function oscillator_pode(q₀=[q₀[1]], p₀=[p₀[1]])
        PODE(oscillator_pode_v, oscillator_pode_f, q₀, p₀)
    end


    function oscillator_sode_v_1(t, q, v, h)
        v[1] = q[1] + h * q[2]
        v[2] = q[2]
        nothing
    end

    function oscillator_sode_v_2(t, q, v, h)
        v[1] = q[1]
        v[2] = q[2] - h * k*q[1]
        nothing
    end

    function oscillator_sode(q₀=q₀)
        SODE((oscillator_sode_v_1, oscillator_sode_v_2), q₀)
    end


    function oscillator_iode_ϑ(t, q, v, p)
        p[1] = q[2]
        p[2] = 0
        nothing
    end

    function oscillator_iode_f(t, q, v, f)
        f[1] = -k*q[1]
        f[2] = v[1] - q[2]
        nothing
    end

    function oscillator_iode_g(t, q, λ, g)
        g[1] = 0
        g[2] = λ[1]
        nothing
    end

    function oscillator_iode_v(t, q, v)
        v[1] = q[2]
        v[2] = -k*q[1]
        nothing
    end

    function oscillator_iode_v(t, q, p, v)
        oscillator_iode_v(t, q, v)
    end

    function oscillator_iode(q₀)
        v₀ = zeros(q₀)
        p₀ = zeros(q₀)
        oscillator_iode_ϑ(0, q₀, v₀, p₀)
        oscillator_iode(q₀, p₀)
    end

    function oscillator_iode(q₀=q₀, p₀=p₀)
        IODE(oscillator_iode_ϑ, oscillator_iode_f,
             oscillator_iode_g, q₀, p₀;
             v=oscillator_iode_v)
    end


    function oscillator_idae_u(t, q, p, λ, u)
        u[1] = λ[1]
        u[2] = λ[2]
        nothing
    end

    function oscillator_idae_g(t, q, p, λ, g)
        g[1] = 0
        g[2] = λ[1]
        nothing
    end

    function oscillator_idae_ϕ(t, q, p, ϕ)
        ϕ[1] = p[1] - q[2]
        ϕ[2] = p[2]
        nothing
    end

    function oscillator_idae(q₀=q₀, p₀=p₀, λ₀=λ₀)
        IDAE(oscillator_iode_f, oscillator_iode_ϑ,
             oscillator_idae_u, oscillator_idae_g,
             oscillator_idae_ϕ, q₀, p₀, λ₀;
             v=oscillator_iode_v)
    end

    function oscillator_pdae_v(t, q, p, v)
        v[1] = q[2]
        v[2] = -k*q[1]
        nothing
    end

    function oscillator_pdae_f(t, q, p, f)
        f[1] = -k*q[1]
        f[2] = p[1] - q[2]
        nothing
    end

    function oscillator_pdae(q₀=q₀, p₀=p₀, λ₀=λ₀)
        PDAE(oscillator_pdae_v, oscillator_pdae_f,
             oscillator_idae_u, oscillator_idae_g,
             oscillator_idae_ϕ, q₀, p₀, λ₀)
    end

end
