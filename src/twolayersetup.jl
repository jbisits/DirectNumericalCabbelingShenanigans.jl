"""
    module TwoLayerDNS
Module containing the setup for a two layer Direct Numerical Simulation, mainly to explore
the cabbeling instability. The two layer model has horizontally uniform initial salinity and
temperature that are set as a hyperbolic tangent vertically to avoid dicontinuities that can
cause the Direct Numerical Simulations to crash. The length over which the transition
between the two layers takes place (i.e. the steepness of the change in the hyperbolic
tangent curve) is a value that can be set.
"""
module TwoLayerDNS

using DirectNumericalCabbelingShenanigans, JLD2, GibbsSeaWater
using DirectNumericalCabbelingShenanigans: simulation_progress

@reexport using GibbsSeaWater

export
    StableUpperLayerInitialConditions,
    CabbelingUpperLayerInitialConditions,
    UnstableUpperLayerInitialConditions,
    IsohalineUpperLayerInitialConditions,
    TwoLayerInitialConditions,
    StableTwoLayerInitialConditions,
    CabbelingTwoLayerInitialConditions,
    UnstableTwoLayerInitialConditions,
    IsohalineTwoLayerInitialConditions,
    set_two_layer_initial_conditions!,
    S₀ˡ, T₀ˡ,
    domain_extent,
    SO_diffusivities,
    non_dimensional_numbers

"""
    abstract type UpperLayerInitialConditions
Abstract super type for initial conditions.
"""
abstract type UpperLayerInitialConditions end
"""
    struct StableUpperLayerInitialConditions
Container for initial salinity and temperature conditions that are stable relative to `S₀ˡ`
and `T₀ˡ`.
"""
struct StableUpperLayerInitialConditions{T} <: UpperLayerInitialConditions
    S₀ᵘ :: T
    T₀ᵘ :: T
end
StableUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ) = StableUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ)
"""
    struct CabbelingUpperLayerInitialConditions
Container for initial salinity and temperature conditions that are unstable to cabbeling
relative to `S₀ˡ` and `T₀ˡ`.
"""
struct CabbelingUpperLayerInitialConditions{T} <: UpperLayerInitialConditions
    S₀ᵘ :: T
    T₀ᵘ :: T
end
CabbelingUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ) =
    CabbelingUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ)
"""
    struct UnstableUpperLayerInitialConditions
Container for initial salinity and temperature conditions that are unstable relative to `S₀ˡ`
and `T₀ˡ`.
"""
struct UnstableUpperLayerInitialConditions{T} <: UpperLayerInitialConditions
    S₀ᵘ :: T
    T₀ᵘ :: T
end
UnstableUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ) =
    UnstableUpperLayerInitialConditions(S₀ᵘ, T₀ᵘ)
"""
    struct IsohalineUpperLayerInitialConditions
Container for isohaline initial salinity at (`S₀ˡ`) and initial temperature conditions `T₀ˡ`.
"""
struct IsohalineUpperLayerInitialConditions{T} <: UpperLayerInitialConditions
    S₀ᵘ :: T
    T₀ᵘ :: T
end
IsohalineUpperLayerInitialConditions(T₀ᵘ) =
    IsohalineUpperLayerInitialConditions(S₀ˡ, T₀ᵘ)
"""
    abstract type TwoLayerInitialConditions
Abstract supertype for two layer model initial conditions.
"""
abstract type TwoLayerInitialConditions end
"""
    struct StableTwoLayerInitialConditions
Container for initial salinity and temperature conditions that are stable.
"""
struct StableTwoLayerInitialConditions{T} <: TwoLayerInitialConditions
    S₀ᵘ :: T
    S₀ˡ :: T
    ΔS₀ :: T
    T₀ᵘ :: T
    T₀ˡ :: T
    ΔT₀ :: T
end
TwoLayerInitialConditions(initial_conditions::StableUpperLayerInitialConditions) =
    StableTwoLayerInitialConditions(initial_conditions.S₀ᵘ, S₀ˡ,
                                    initial_conditions.S₀ᵘ - S₀ˡ, initial_conditions.T₀ᵘ,
                                    T₀ˡ, initial_conditions.T₀ᵘ -T₀ˡ)
"""
    struct CabbelingTwoLayerInitialConditions
Container for initial salinity and temperature conditions that are unstable to cabbeling.
"""
struct CabbelingTwoLayerInitialConditions{T} <: TwoLayerInitialConditions
    S₀ᵘ :: T
    S₀ˡ :: T
    ΔS₀ :: T
    T₀ᵘ :: T
    T₀ˡ :: T
    ΔT₀ :: T
end
TwoLayerInitialConditions(initial_conditions::CabbelingUpperLayerInitialConditions) =
    CabbelingTwoLayerInitialConditions(initial_conditions.S₀ᵘ, S₀ˡ,
                                       initial_conditions.S₀ᵘ - S₀ˡ, initial_conditions.T₀ᵘ,
                                       T₀ˡ, initial_conditions.T₀ᵘ -T₀ˡ)
"""
    struct UnstableTwoLayerInitialConditions
Container for initial salinity and temperature conditions that are gravitationally unstable.
"""
struct UnstableTwoLayerInitialConditions{T} <: TwoLayerInitialConditions
    S₀ᵘ :: T
    S₀ˡ :: T
    ΔS₀ :: T
    T₀ᵘ :: T
    T₀ˡ :: T
    ΔT₀ :: T
end
TwoLayerInitialConditions(initial_conditions::UnstableUpperLayerInitialConditions) =
    UnstableTwoLayerInitialConditions(initial_conditions.S₀ᵘ, S₀ˡ,
                                      initial_conditions.S₀ᵘ - S₀ˡ, initial_conditions.T₀ᵘ,
                                      T₀ˡ, initial_conditions.T₀ᵘ -T₀ˡ)
                                      """
    struct IsohalineTwoLayerInitialConditions
Container for initial salinity and temperature conditions that are gravitationally unstable.
"""
struct IsohalineTwoLayerInitialConditions{T} <: TwoLayerInitialConditions
    S₀ᵘ :: T
    S₀ˡ :: T
    ΔS₀ :: T
    T₀ᵘ :: T
    T₀ˡ :: T
    ΔT₀ :: T
end
TwoLayerInitialConditions(initial_conditions::IsohalineUpperLayerInitialConditions) =
    IsohalineTwoLayerInitialConditions(initial_conditions.S₀ᵘ, S₀ˡ,
                                      initial_conditions.S₀ᵘ - S₀ˡ, initial_conditions.T₀ᵘ,
                                      T₀ˡ, initial_conditions.T₀ᵘ -T₀ˡ)
"""
    const T₀ˡ = 0.5
Lower layer initial temperature across all two layer experiments.
"""
const T₀ˡ = 0.5
"""
    const S₀ˡ = 34.7
Lower layer initial salinity across all two layer experiments.
"""
const S₀ˡ = 34.7
"""
    const domain_extent
Domain extent on which the two layer simulations are run.
"""
const domain_extent = (Lx = 0.1, Ly = 0.1, Lz = 1)
"""
    const SO_diffusivities
Diffusivity estimates for the Southern Ocean.
"""
const SO_diffusivities = (ν = 1e-6, κ = (S = 1e-9, T = 1e-7))
"""
    function set_two_layer_initial_conditions(model::Oceananigans.AbstractModel,
                                              initial_conditions::TwoLayerInitialConditions;
                                              interface_location = 0.5,
                                              interface_thickness = 100,
                                              salinity_perturbation_width = 100)
Set initial conditions for a two layer model with hyperbolic tangent transition between the
upper and lower layers.
Function arguments:

- `model`: to set the initial salinity and temperature in;
- `initial_conditions`: the values for the initial conditions in an appropriate container.

Keyword arguments:

- `interface_location`: location of the interface of the two layers;
- `interface_thickness`: width of the hyperbolic tangent for setting the change betwen the
two layers;
- `perturb_salinity`: whether or not to peturb the salinity in the upper layer to form an
instability;
- `salinity_perturbation_width`: width of the Gaussian for the salinity perturbation in the
upper layer. This is what creates the instability to cause mixing.
"""
function set_two_layer_initial_conditions!(model::Oceananigans.AbstractModel,
                                           initial_conditions::TwoLayerInitialConditions;
                                           interface_location = 0.5,
                                           interface_thickness = 100,
                                           perturb_salinity = true,
                                           salinity_perturbation_width = 100)

    ΔS = initial_conditions.ΔS₀ / 2
    ΔT = initial_conditions.ΔT₀ / 2

    initial_S_profile(x, y, z) = perturb_salinity == true ?
                                 ΔS * tanh(interface_thickness * (z + interface_location)) +
                                 (initial_conditions.S₀ˡ + ΔS) +
                                  perturb_salintiy(z, interface_location,
                                                   salinity_perturbation_width) :
                                 ΔS * tanh(interface_thickness * (z + interface_location)) +
                                 (initial_conditions.S₀ˡ + ΔS)
    initial_T_profile(x, y, z) = ΔT * tanh(interface_thickness * (z + interface_location)) +
                                 (initial_conditions.T₀ˡ + ΔT)

    set!(model, S = initial_S_profile, T = initial_T_profile)

    return nothing

end
"""
    function perturb_salintiy(z, interface_location)
Where and what value to add to perturb the salinity initial condition.
"""
function perturb_salintiy(z, interface_location, salinity_perturbation_width)
    if z > -interface_location
        exp(-((z + interface_location) - (interface_location / 2))^2 /
              2*(salinity_perturbation_width)^2) / sqrt(2*π*salinity_perturbation_width^2)
    else
        0
    end
end
"""
    function non_dimensional_numbers(model::Oceananigans.AbstractModel,
                                     initial_conditions::TwoLayerInitialConditions)
Compute non-dimensional numbers related to the DNS experiments. The non-dimensional numbers
are:

- Prandtl number: ``Pr = ν / κₜ``
- Schmidt number: ``Sc = ν / κₛ``
- Lewis number:   ``Le = κₜ / κₛ``
- Raleigh number (density): ``Ra_{d} = Ra_{t} / Ra_{s} = (αΔT / βΔS) * (1 / Le)``.

These numbers are then saved into the simulation output file.
"""
function non_dimensional_numbers(model::Oceananigans.AbstractModel,
                                 initial_conditions::TwoLayerInitialConditions)

    ν = model.closure.ν
    κₛ, κₜ = model.closure.κ
    Pr = ν / κₜ
    Sc = ν / κₛ
    Le = κₜ / κₛ
    α = gsw_alpha(initial_conditions.S₀ˡ, initial_conditions.T₀ˡ, 0)
    β = gsw_beta(initial_conditions.S₀ˡ, initial_conditions.T₀ˡ, 0)
    Ra = ((α * initial_conditions.ΔT₀ )/ (β * initial_conditions.ΔS₀)) * (1 / Le)

    return Dict("Pr" => Pr, "Sc" => Sc, "Le" => Le, "Ra_ρ" => Ra)

end
"""
    function DNS_simulation_setup(model::Oceananigans.AbstractModel, Δt::Number,
                                  stop_time::Number,
                                  initial_conditions::TwoLayerInitialConditions)
Setup a DNS from `initial_conditions` that are of type `TwoLayerInitialConditions`.
Important non-dimensional numnbers that are part of this experiment are computed and saved
to the simulation output file.
"""
function DNCS.DNS_simulation_setup(model::Oceananigans.AbstractModel, Δt::Number,
                                   stop_time::Number,
                                   initial_conditions::TwoLayerInitialConditions;
                                   cfl = 0.75,
                                   diffusive_cfl = 0.75,
                                   max_change = 1.2,
                                   max_Δt = 1e-2)

    simulation = Simulation(model; Δt, stop_time)

    # time step adjustments
    wizard = TimeStepWizard(; cfl, diffusive_cfl, max_change, max_Δt)
    simulation.callbacks[:wizard] = Callback(wizard, IterationInterval(10))

    # save output
    outputs = (S = model.tracers.S, T = model.tracers.T)
    filename = form_filename(initial_conditions)
    simulation.output_writers[:outputs] = JLD2OutputWriter(model, outputs,
                                                    filename = filename,
                                                    schedule = IterationInterval(50),
                                                    overwrite_existing = true)
    jldopen(filename, "a+") do file
        file["Non_dimensional_numbers"] = non_dimensional_numbers(model, initial_conditions)
    end

    # progress reporting
    simulation.callbacks[:progress] = Callback(simulation_progress, IterationInterval(50))

    return simulation

end
"""
    function form_filename(initial_conditions::TwoLayerInitialConditions)
Create a directory based on the temperature of the upper layer and a file for the saved
output based on the type of initial condition (i.e. stable, cabbeling or unstable).
"""
function form_filename(initial_conditions::TwoLayerInitialConditions)

    parameter = typeof(initial_conditions.S₀ᵘ)
    ic_type = typeof(initial_conditions)
    savefile = ic_type == StableTwoLayerInitialConditions{parameter} ? "stable" :
                            ic_type == CabbelingTwoLayerInitialConditions{parameter} ?
                                "cabbeling" :
                                ic_type == UnstableTwoLayerInitialConditions{parameter} ?
                                "unstable" : "isohaline"
    filename = joinpath(SIMULATION_PATH, savefile * ".jld2")

    return filename

end

end # module
