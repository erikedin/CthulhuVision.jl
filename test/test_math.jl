using Test
using CthulhuVision.Random
using CthulhuVision.Math

using CUDAnative, CuArrays

@inline function randomunitvectors_gpu(result, n)
    index = threadIdx().x + (blockIdx().x - 1) * blockDim().x

    seedgen = SplitMix64(index)
    s0 = next(seedgen)
    s1 = next(seedgen)
    s2 = next(seedgen)
    s3 = next(seedgen)
    rng = UniformRNG(Xoshiro256pp(s0, s1, s2, s3))

    if index <= n
        @inbounds result[index] = randominunitsphere(rng)
    end

    nothing
end

@testset "Math GPU                " begin
    @testset "Random vectors in unit sphere have length < 1.0f0" begin
        threads = 32
        blocks = 8
        n = threads * blocks
        result = CuArray{Vec3}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=threads blocks=blocks randomunitvectors_gpu(result, n)
        end

        result_host = Vector{Vec3}(result)

        for i = 1:n
            v = result_host[i]
            l = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
            @test l < 1.0f0
        end
    end
end

struct TTV
    v::Vec3
    t::Transform
    expected::Vec3
end

@testset "Math Transform          " begin
    vec3_transforms = [
        TTV(
            Vec3(0f0, 0f0, 0f0),
            translation(1f0, 0f0, 0f0),
            Vec3(1f0, 0f0, 0f0),
        ),

        TTV(
            Vec3(0f0, 0f0, 0f0),
            translation(0f0, 1f0, 0f0),
            Vec3(0f0, 1f0, 0f0),
        ),

        TTV(
            Vec3(0f0, 0f0, 0f0),
            translation(0f0, 0f0, 1f0),
            Vec3(0f0, 0f0, 1f0),
        ),

        TTV(
            Vec3(0f0, 0f0, 0f0),
            translation(1f0, 2f0, 3f0),
            Vec3(1f0, 2f0, 3f0),
        ),

        TTV(
            Vec3(4f0, 5f0, 6f0),
            translation(1f0, 2f0, 3f0),
            Vec3(5f0, 7f0, 9f0),
        ),

        TTV(
            Vec3(2f0, 0f0, 0f0),
            translation(1f0, 0f0, 0f0),
            Vec3(3f0, 0f0, 0f0),
        ),
    ]

    @testset "Transform * Vector" begin
        for ttv in vec3_transforms
            actual = ttv.t * ttv.v

            @test actual == ttv.expected
        end
    end
end