using Test

using CthulhuVision.BVH
using CthulhuVision.Light
using CthulhuVision.Math

struct TV
    aabb::AABB
    ray::Ray
    tmin::Float32
    tmax::Float32
    description::String

    function TV(; 
        description = "",
        center      = Vec3(0.0f0, 0.0f0, 100.0f0),
        size        = Vec3(5.0f0, 2.0f0, 8.0f0),
        origin      = Vec3(0.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(0.0f0, 0.0f0, 1.0f0),
        tmin        = 0.0f0,
        tmax        = typemax(Float32))

        aabb = AABB(center - size, center + size)
        ray = Ray(origin, direction)
        new(aabb, ray, tmin, tmax, description)
    end
end

standardcenter = Vec3(0.0f0, 0.0f0, 100.0f0)
standardsize   = Vec3(5.0f0, 2.0f0, 8.0f0)
hits = [
    #
    # In the x direction only
    #
    TV(
        description = "Ray at constant x = 0 hits center of AABB",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(0.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(0.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "AABB translated x - 100, origin translated -100",
        center      = standardcenter - Vec3(100.0f0, 0.0f0, 0.0f0),
        size        = standardsize,
        origin      = Vec3(-100.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(   0.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "AABB translated x + 100, origin translated +100",
        center      = standardcenter + Vec3(100.0f0, 0.0f0, 0.0f0),
        size        = standardsize,
        origin      = Vec3(100.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(  0.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "Origin at -100, dx = +1",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(-100.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(   1.0f0, 0.0f0, 1.0f0),
    ),

    # The x and y direction
    TV(
        description = "Origin at x=-100, y=-50, dx = +1, dy = +0.5f",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(-100.0f0, -50.0f0, 0.0f0),
        direction   = Vec3(   1.0f0,   0.5f0, 1.0f0),
    ),

    TV(
        description = "Origin at x=100, y=-50, dx = -1, dy = +0.5f",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(100.0f0, -50.0f0, 0.0f0),
        direction   = Vec3( -1.0f0,   0.5f0, 1.0f0),
    ),
]

nohits = [
    #
    # In the x direction only
    #
    TV(
        description = "Ray at constant x = -10 does not hit the AABB",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(-10.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(  0.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "Ray at constant x = +10 does not hit the AABB",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3( 10.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(  0.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "Origin at -100, dx = -1, which is the other direction",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(-100.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(  -1.0f0, 0.0f0, 1.0f0),
    ),

    TV(
        description = "Origin at y=-100, dy = -1, which is the other direction",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(-100.0f0, -100.0f0, 0.0f0),
        direction   = Vec3(   1.0f0,   -1.0f0, 1.0f0),
    ),

    TV(
        description = "Origin at z=0, dz = -1, which is the other direction",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(   0.0f0,    0.0f0,  0.0f0),
        direction   = Vec3(   0.0f0,    0.0f0, -1.0f0),
    ),

    TV(
        description = "Hit at t = 100, but tmax < 100",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(0.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(0.0f0, 0.0f0, 1.0f0),
        tmax        = 20.0f0,
    ),

    TV(
        description = "Hit at t = 100, but tmin > 100",
        center      = standardcenter,
        size        = standardsize,
        origin      = Vec3(0.0f0, 0.0f0, 0.0f0),
        direction   = Vec3(0.0f0, 0.0f0, 1.0f0),
        tmin        = 200.0f0,
    ),
]

@testset "BVH CPU                 " begin
    # A standard AABB is used for most tests:
    # center at 0.0f0, 0.0f0, 100.0f0
    # x: -5 <= x <= 5
    # y: -2 <= y <= 2
    # z: -8 <= z <= 8
    @testset "AABB; Test vectors that should hit" begin
        for tv in hits
            @testset "$(tv.description)" begin
                @test hit(tv.aabb, tv.ray, tv.tmin, tv.tmax)
            end
        end
    end

    @testset "AABB; Test vectors that should not hit" begin
        for tv in nohits
            @testset "$(tv.description)" begin
                @test !hit(tv.aabb, tv.ray, tv.tmin, tv.tmax)
            end
        end
    end
end

function ishit_gpu(aabb, ray, tmin, tmax, result)
    x = threadIdx().x

    if x == 1
        result[1] = hit(aabb, ray, tmin, tmax)
    end

    nothing
end

@testset "BVH GPU                 " begin
    @testset "AABB; Test vectors that should hit" begin
        for tv in hits
            @testset "$(tv.description)" begin
                result = CuArray{Bool}(undef, 1)

                CUDAnative.@sync begin
                    @cuda threads=16 blocks=1 ishit_gpu(tv.aabb, tv.ray, tv.tmin, tv.tmax, result)
                end
                resulthost = Vector{Bool}(result)
                ishit = resulthost[1]

                @test ishit
            end
        end
    end
    
    @testset "AABB; Test vectors that should not hit" begin
        for tv in nohits
            @testset "$(tv.description)" begin
                result = CuArray{Bool}(undef, 1)

                CUDAnative.@sync begin
                    @cuda threads=16 blocks=1 ishit_gpu(tv.aabb, tv.ray, tv.tmin, tv.tmax, result)
                end
                resulthost = Vector{Bool}(result)
                ishit = resulthost[1]

                @test !ishit
            end
        end
    end
end