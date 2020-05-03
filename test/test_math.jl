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

@testset "Math Transform          " begin
    @testset "Matrix * Matrix" begin
        a = [1f0  2f0  3f0  4f0 ;
             5f0  6f0  7f0  8f0 ;
             9f0  10f0 11f0 12f0;
             13f0 14f0 15f0 16f0]
        b = [17f0 18f0 19f0 20f0;
             21f0 22f0 23f0 24f0;
             25f0 26f0 27f0 28f0;
             29f0 30f0 31f0 32f0]

        m = Transform(
            1f0,  2f0,  3f0,  4f0,
            5f0,  6f0,  7f0,  8f0,
            9f0, 10f0, 11f0, 12f0,
            13f0, 14f0, 15f0, 16f0,
        )
        k = Transform(
            17f0, 18f0, 19f0, 20f0,
            21f0, 22f0, 23f0, 24f0,
            25f0, 26f0, 27f0, 28f0,
            29f0, 30f0, 31f0, 32f0,
        )

        ab = a * b
        ba = b * a
        mk = m * k
        km = k * m

        @test ab[1, 1] == mk.e11
        @test ab[1, 2] == mk.e12
        @test ab[1, 3] == mk.e13
        @test ab[1, 4] == mk.e14

        @test ab[2, 1] == mk.e21
        @test ab[2, 2] == mk.e22
        @test ab[2, 3] == mk.e23
        @test ab[2, 4] == mk.e24

        @test ab[3, 1] == mk.e31
        @test ab[3, 2] == mk.e32
        @test ab[3, 3] == mk.e33
        @test ab[3, 4] == mk.e34

        @test ab[4, 1] == mk.e41
        @test ab[4, 2] == mk.e42
        @test ab[4, 3] == mk.e43
        @test ab[4, 4] == mk.e44

        @test ba[1, 1] == km.e11
        @test ba[1, 2] == km.e12
        @test ba[1, 3] == km.e13
        @test ba[1, 4] == km.e14

        @test ba[2, 1] == km.e21
        @test ba[2, 2] == km.e22
        @test ba[2, 3] == km.e23
        @test ba[2, 4] == km.e24

        @test ba[3, 1] == km.e31
        @test ba[3, 2] == km.e32
        @test ba[3, 3] == km.e33
        @test ba[3, 4] == km.e34

        @test ba[4, 1] == km.e41
        @test ba[4, 2] == km.e42
        @test ba[4, 3] == km.e43
        @test ba[4, 4] == km.e44

    end

    @testset "Matrix * Vector" begin
        a = [1f0  2f0  3f0  4f0 ;
             5f0  6f0  7f0  8f0 ;
             9f0  10f0 11f0 12f0;
             13f0 14f0 15f0 16f0]
        b = [17f0; 18f0; 19f0; 1f0]

        m = Transform(
            1f0,  2f0,  3f0,  4f0,
            5f0,  6f0,  7f0,  8f0,
            9f0, 10f0, 11f0, 12f0,
            13f0, 14f0, 15f0, 16f0,
        )
        k = Vec3(17f0, 18f0, 19f0)

        ab = a * b
        mk = m * k

        @test ab[1] == mk.x
        @test ab[2] == mk.y
        @test ab[3] == mk.z
    end
end