using Test

using CUDAnative
using CuArrays

using CthulhuVision.BVH
using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Materials
using CthulhuVision.Spheres

@testset "BVH Build" begin
    rng = uniformfromindex(1)
    material = dielectric(1.5f0)

    spheres = Vector{Sphere}()
    for x = -500.0f0:100.0f0:500.0f0
        for y = -500.0f0:100.0f0:500.0f0
            for z in [-10000.0f0, 10000.0f0]
                push!(spheres, Sphere(Vec3(x, y, 10000.0f0), 1.0f0, material))
            end
        end
    end
    # TODO More spheres here

    bvh = bvhbuilder(spheres, rng)
end