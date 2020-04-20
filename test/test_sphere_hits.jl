using Test

using CUDAnative
using CuArrays

using CthulhuVision.BVH
using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Materials
using CthulhuVision.Spheres

function spherehit_gpu(sphere, ray, ishit)
    x = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if x == 1
        rec = hit(sphere, 0.0f0, typemax(Float32), ray)
        @cuprintln("Ray at sphere 1 is a hit? $(rec.ishit)")
        ishit[1] = rec.ishit
    end
    nothing
end

@testset "Sphere hits GPU" begin
    @testset "Sphere 1" begin
        material = dielectric(1.5f0)
        sphere = Sphere(Vec3(0.0f0, 0.0f0, -10.0f0), 1.0f0, material)
        ray = Ray(Vec3(0.0f0, 0.0f0, 0.0f0), Vec3(0.0f0, 0.0f0, -10.0f0))

        ishit_d = CuArray{Bool}(undef, 1)

        CUDAnative.@sync begin
            @cuda threads=16 spherehit_gpu(sphere, ray, ishit_d)
        end

        ishit_host = Vector{Bool}(ishit_d)
        @test ishit_host[1]
    end
    
    @testset "Sphere 2" begin
        material = dielectric(1.5f0)
        sphere = Sphere(Vec3(-500.0f0, -500.0f0, -10000.0f0), 1.0f0, material)
        ray = Ray(Vec3(0.0f0, 0.0f0, 0.0f0), Vec3(-500.0f0, -500.0f0, -10000.0f0))

        ishit_d = CuArray{Bool}(undef, 1)

        CUDAnative.@sync begin
            @cuda threads=16 spherehit_gpu(sphere, ray, ishit_d)
        end

        ishit_host = Vector{Bool}(ishit_d)
        @test ishit_host[1]
    end
end