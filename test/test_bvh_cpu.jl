using Test

using CUDAnative
using CuArrays

using CthulhuVision.BVH
using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Materials
using CthulhuVision.Spheres

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

#@testset "BVH CPU                 " begin
    ## A standard AABB is used for most tests:
    ## center at 0.0f0, 0.0f0, 100.0f0
    ## x: -5 <= x <= 5
    ## y: -2 <= y <= 2
    ## z: -8 <= z <= 8
    #@testset "AABB; Test vectors that should hit" begin
        #for tv in hits
            #@testset "$(tv.description)" begin
                #@test hit(tv.aabb, tv.ray, tv.tmin, tv.tmax)
            #end
        #end
    #end

    #@testset "AABB; Test vectors that should not hit" begin
        #for tv in nohits
            #@testset "$(tv.description)" begin
                #@test !hit(tv.aabb, tv.ray, tv.tmin, tv.tmax)
            #end
        #end
    #end
#end

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

function bvhhit_gpu(bvh, spheres, targets, bvhtraversal, ishit)
    x = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    n = length(targets)
    o = Vec3(0.0f0, 0.0f0, 0.0f0)

    trav = TraversalList(bvhtraversal)
    bvhworld = BVHWorld(bvh, spheres, trav)
    
    if x <= 1
        target = targets[x]
        ray = Ray(o, target)
        rec = hit(bvhworld, 0.0f0, typemax(Float32), ray)
        ishit[x] = rec.ishit
    end
    nothing
end

@testset "BVH CPU and GPU         " begin
    @testset "Regular squares of spheres accelerated by BVH: Hits" begin
        # 10 000 units away in all dimensions there are squares of 11x11 spheres,
        # regularly spaces with centers 100 units between. The radius is 1 for each sphere.
        # For z = 10 000, for instance, the spheres are at
        # x: -500, -400, -300, -200, -100, 0, 100, 200, 300, 400, 500
        # y: -500, -400, -300, -200, -100, 0, 100, 200, 300, 400, 500
        
        # Aiming a Ray from the origin to the center of each sphere should be a
        # hit.


        rng = uniformfromindex(1)
        material = dielectric(1.5f0)

        spheres = Vector{Sphere}()
        for x = -500.0f0:500.0f0:500.0f0
            for y = -500.0f0:500.0f0:500.0f0
                for z in [-10000.0f0]
                    push!(spheres, Sphere(Vec3(x, y, z), 1.0f0, material))
                end
            end
        end
        # TODO More spheres here

        bvh = bvhbuilder(spheres, rng)

        threads = 256
        blocks = ceil(Int, length(spheres) / threads)

        bvh_d = CuArray{BVHNode}(bvh)
        spheres_d = CuArray{Sphere}(spheres)
        targets_d = CuArray{Vec3}([s.center for s in spheres])
        bvhtraversal = CuArray{UInt32}(undef, length(spheres))
        ishit_d = CuArray{Bool}(undef, length(spheres))
        
        CUDAnative.@sync begin
            @cuda threads=threads blocks=blocks bvhhit_gpu(bvh_d, spheres_d, targets_d, bvhtraversal, ishit_d)
        end

        ishit = Vector{Bool}(ishit_d)

        for (i, b) in enumerate(ishit)
            @testset "Sphere $(i): Is hit" begin
                @test b
            end
        end
    end
    
    # @testset "Regular squares of spheres accelerated by BVH: No hits" begin
    #     # 10 000 units away in all dimensions there are squares of 11x11 spheres,
    #     # regularly spaces with centers 100 units between. The radius is 1 for each sphere.
    #     # For z = 10 000, for instance, the spheres are at
    #     # x: -500, -400, -300, -200, -100, 0, 100, 200, 300, 400, 500
    #     # y: -500, -400, -300, -200, -100, 0, 100, 200, 300, 400, 500
        
    #     # Aiming a Ray from the origin to the center of each sphere should be a
    #     # hit.


    #     rng = uniformfromindex(1)
    #     material = dielectric(1.5f0)

    #     spheres = Vector{Sphere}()
    #         Sphere(Vec3(x, y, 10000.0f0), 1.0f0, material)
        
    #     for x = -500.0f0:100.0f0:500.0f0
    #         for y = -500.0f0:100.0f0:500.0f0
    #             for z = [-10000.0f0, 10000.0f0]
    #                 push!(spheres, Sphere(Vec3(x, y, 10000.0f0), 1.0f0, material))
    #             end
    #         end
    #     end
    #     offsetxy = Vec3(5.0f0, 5.0f0, 0.0f0)
    #     targets = [s.center + offsetxy for s in spheres]

    #     bvh = bvhbuilder(spheres, rng)

    #     threads = 256
    #     blocks = ceil(Int, length(spheres) / threads)

    #     bvh_d = CuArray{BVHNode}(bvh)
    #     spheres_d = CuArray{Sphere}(spheres)
    #     targets_d = CuArray{Vec3}(targets)
    #     bvhtraversal = CuArray{UInt32}(undef, length(spheres))
    #     ishit_d = CuArray{Bool}(undef, length(spheres))
        
    #     CUDAnative.@sync begin
    #         @cuda threads=threads blocks=blocks bvhhit_gpu(bvh_d, spheres, targets_d, bvhtraversal, ishit_d)
    #     end

    #     ishit = Vector{Bool}(ishit_d)

    #     for b in ishit
    #         @test !b
    #     end
    # end
end