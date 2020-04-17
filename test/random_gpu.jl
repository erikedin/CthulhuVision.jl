using Test
using CUDAnative
using CuArrays

using CthulhuVision.Random
using CthulhuVision.Rendering: makeprng

function splitmix64_gpu(seed::UInt64, n::Int, result)

    x = threadIdx().x

    if x == 1
        sm = SplitMix64(seed)
        for i = 1:n
            @inbounds result[i] = next(sm)
        end
    end

    nothing
end

function xoshiro256pp_gpu(s0::UInt64, s1::UInt64, s2::UInt64, s3::UInt64, n::Int, result)

    x = threadIdx().x

    if x == 1
        r = Xoshiro256pp(s0, s1, s2, s3)
        for i = 1:n
            @inbounds result[i] = next(r)
        end
    end

    nothing
end

function uniform32_gpu(us, fs, n::Int)

    x = threadIdx().x

    if x == 1
        for i = 1:n
            @inbounds fs[i] = uniform32(us[i])
        end
    end

    nothing
end

# This kernel tests the factory function that creates a PRNG, with a seed value
# generated from the CUDA thread and block indices.
# Each thread generates a single Float32 value from the PRNG, and stores it in
# the `values` array. This allows us to verify that all Float32 values are different,
# so that we don't accidentally use a single seed, or a seed that repeats.
function prng_from_thread_and_block_gpu(values, n)
    idx = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if idx <= n
        rng = makeprng()
        @inbounds values[idx] = next(rng)
    end
    nothing
end

# These test values were generated from the C code available at
# http://prng.di.unimi.it/splitmix64.c
# 2020-04-16

@testset "CthulhuVision.Random GPU" begin
    @testset "uniform32 is 0.0f0 <= x < 1.0f0" begin
        n = 1000
        us = CuArray{UInt64}(rand(UInt64, n))
        fs = CuArray{Float32}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=16 uniform32_gpu(us, fs, n)
        end

        floats_host = Vector{Float32}(fs)

        for k in floats_host
            @test 0.0f0 <= k < 1.0f0
        end
    end

    @testset "SplitMix64 validation: Seed 0" begin
        n = 100
        result = CuArray{UInt64}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=16 splitmix64_gpu(UInt64(0), n, result)
        end

        # Seed 0x0000000000000000:
        fromseed0 = [
            0xe220a8397b1dcdaf, 0x6e789e6aa1b965f4, 0x06c45d188009454f, 0xf88bb8a8724c81ec, 0x1b39896a51a8749b, 
            0x53cb9f0c747ea2ea, 0x2c829abe1f4532e1, 0xc584133ac916ab3c, 0x3ee5789041c98ac3, 0xf3b8488c368cb0a6, 
            0x657eecdd3cb13d09, 0xc2d326e0055bdef6, 0x8621a03fe0bbdb7b, 0x8e1f7555983aa92f, 0xb54e0f1600cc4d19, 
            0x84bb3f97971d80ab, 0x7d29825c75521255, 0xc3cf17102b7f7f86, 0x3466e9a083914f64, 0xd81a8d2b5a4485ac, 
            0xdb01602b100b9ed7, 0xa9038a921825f10d, 0xedf5f1d90dca2f6a, 0x54496ad67bd2634c, 0xdd7c01d4f5407269, 
            0x935e82f1db4c4f7b, 0x69b82ebc92233300, 0x40d29eb57de1d510, 0xa2f09dabb45c6316, 0xee521d7a0f4d3872, 
            0xf16952ee72f3454f, 0x377d35dea8e40225, 0x0c7de8064963bab0, 0x05582d37111ac529, 0xd254741f599dc6f7, 
            0x69630f7593d108c3, 0x417ef96181daa383, 0x3c3c41a3b43343a1, 0x6e19905dcbe531df, 0x4fa9fa7324851729, 
            0x84eb4454a792922a, 0x134f7096918175ce, 0x07dc930b302278a8, 0x12c015a97019e937, 0xcc06c31652ebf438, 
            0xecee65630a691e37, 0x3e84ecb1763e79ad, 0x690ed476743aae49, 0x774615d7b1a1f2e1, 0x22b353f04f4f52da, 
            0xe3ddd86ba71a5eb1, 0xdf268adeb6513356, 0x2098eb73d4367d77, 0x03d6845323ce3c71, 0xc952c5620043c714, 
            0x9b196bca844f1705, 0x30260345dd9e0ec1, 0xcf448a5882bb9698, 0xf4a578dccbc87656, 0xbfdeaed9a17b3c8f, 
            0xed79402d1d5c5d7b, 0x55f070ab1cbbf170, 0x3e00a34929a88f1d, 0xe255b237b8bb18fb, 0x2a7b67af6c6ad50e, 
            0x466d5e7f3e46f143, 0x42375cb399a4fc72, 0x8c8a1f148a8bb259, 0x32fcab5daed5bdfc, 0x9e60398c8d8553c0, 
            0xee89cceb8c4064c0, 0xdb0215941d86a66f, 0x5ccde78203c367a8, 0xf1bcbc6a1ec11786, 0xef054fceee954551, 
            0xdf82012d0555c6df, 0x292566ff72403c08, 0xc4dd302a1bfa1137, 0xd85f219db5c554e1, 0x6a27ff807441bcd2, 
            0x96a573e9b48216e8, 0x46a9fdac40bf0048, 0x3dd12464a0ee15b4, 0x451e521296a7eea1, 0x56e4398a98f8a0fd, 
            0x7b7dc2160e3335a7, 0xc679ee0bebcb1cca, 0x928d6f2d7453424e, 0x1b38994205234c6d, 0x8086d193a6f2b568, 
            0x21c6e26639ac2c65, 0xd9dccac414d23c6f, 0x91cd642057e00235, 0x77fc607dc6589373, 0x05b8abe26dd3aee7, 
            0x12f6436ac376cc66, 0x64952424897b2307, 0xee8c2baf6343e5c3, 0xdc4c613d9eba2304, 0x3505b7796bd1a506, 
        ]

        result_host = Vector{UInt64}(result)

        for i = 1:n
            @test result_host[i] == fromseed0[i]
        end
    end

    @testset "SplitMix64 validation: Seed 0x1234567890123456" begin
        n = 100
        result = CuArray{UInt64}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=16 splitmix64_gpu(0x1234567890123456, n, result)
        end

        # Seed 0x1234567890123456:
        fromseed123 = [
            0xa747f481346acb72, 0x8ad918349ab73966, 0xbec62b7cc97a0873, 0xf4975b3f04f272de, 0x309a2a499503b323, 
            0x75f0d35e440c1380, 0xa0e250c4832f2146, 0x5000ad7279d4564d, 0x527f776bf010fc54, 0xb178837968cf7887, 
            0x03a2b6f219eb2ac9, 0x0c292f6dac0b89ce, 0xf406a38407ab8e94, 0x675980f999c91458, 0x888499c0bc4770c8, 
            0x410c7af835212035, 0xf1a2cce43237861f, 0x1b3988311d0850c3, 0x70dc6bfcab337fc3, 0x12cec9bb9600463d, 
            0xbce1012111683484, 0x63d63227c1131aef, 0x935018dead98b912, 0x50427855dd872b27, 0x5e1701eb8aed1c32, 
            0x3231ecfe36e059f7, 0x3ee6eae41b75b100, 0x8640df45d78097ac, 0x6bd68158bdc48a49, 0xaa6af115f13bed47, 
            0x9680ce74a4a7e996, 0x4b7d22f3cbd00a25, 0xc71682b11cc96c07, 0x663a228deabdf2b1, 0x75018ae2ecab3af5, 
            0x0e6c0c485496b5db, 0x4f5f6e4b5283597f, 0x51a2c78fa67277c2, 0x7d6587ff16a97e90, 0x0226d182b0dd9a48, 
            0x61b5565f8c28bd10, 0x9201bb21659aefd1, 0x3971d699e9f55c64, 0x0a3d12bae04ab182, 0xcbaf187d97a60d1e, 
            0x2615a8f09a9a6b7a, 0xef5b6a1cbcabf696, 0x4dd54df163973e33, 0xe4b483b1d6762fbf, 0x3bd5b1a09a569677, 
            0x49b90c90ce82c302, 0xf193d2253c266d22, 0xf885d93f2e56a330, 0xc6fdf5a84b29694a, 0x84b09a60cd8f6d50, 
            0x859bdff3c39724b9, 0x8f7bf534dfdb6f8b, 0x162ade8198d9f7dd, 0x56d5af032eb87ad9, 0x961bf7f92b4da6cf, 
            0x189850a17f576b2e, 0x52661a31fc19528f, 0x4486fe7a2234d24b, 0xea4d0bbe2643c140, 0xd682459a551543b1, 
            0xee1c33c957b2b3c2, 0x5d3c39bcd8abf73b, 0xcfb078345aae27ae, 0xdd8cae3594569323, 0xb5c53b2f99372232, 
            0x358f6866529407ca, 0xadf308a600d090a2, 0xe16cb21fb6a309a7, 0x07f86d1786ef4264, 0x317f3628ac7ccc19, 
            0x8d78766af85d7ce4, 0x8d8790adea039d5e, 0x17c8ff07ebccb417, 0x93be8e429f5d8b3e, 0x8893278971571734, 
            0xce4f4aab2da09bde, 0xe75a99e8d6afd288, 0xae74da6eea491702, 0xce202d270eca927c, 0x040cf01b89c75d41, 
            0x2c9608b9e1138f11, 0x5a23a33b63d4cdb1, 0x5f1064ca5b023240, 0x180712765e0c7518, 0xb409002087be28db, 
            0x15582962b3b3dd73, 0x1fc1c3a0880262c2, 0x99dd5b63f583202f, 0x99da0a71d47b3176, 0x7cd6a4aa5b2760c8, 
            0xea5d86aa35596e3e, 0x28c3164807d7201a, 0x7203b1f76c6e2866, 0x3911c8344d36bd8b, 0x580cc832a21b96c6, 
        ]

        result_host = Vector{UInt64}(result)

        for i = 1:n
            @test result_host[i] == fromseed123[i]
        end
    end

    @testset "Xoshiro256++ validation: First seed" begin
        n = 100
        result = CuArray{UInt64}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=16 xoshiro256pp_gpu(0xe220a8397b1dcdaf, 0x6e789e6aa1b965f4, 0x06c45d188009454f, 0xf88bb8a8724c81ec, n, result)
        end

        # The seeds are taken from the SplitMix64 test vectors.
        # Seed 0xe220a8397b1dcdaf 0x6e789e6aa1b965f4 0x06c45d188009454f 0xf88bb8a8724c81ec:
        xshr256_test_1 = [
            0x53175d61490b23df, 0x61da6f3dc380d507, 0x5c0fdf91ec9a7bfc, 0x02eebf8c3bbe5e1a, 0x7eca04ebaf4a5eea, 
            0x0543c37757f08d9a, 0xdb7490c75ab5026e, 0xd87343e6464bc959, 0x4b7da0a02389f0ff, 0x1300fc58c0424c16, 
            0x5084843206c19968, 0x10ea073de9aa4dfc, 0x1aae554343960cc1, 0x1804139f10fae720, 0x10d790e7b8ac10fa, 
            0x667d2bffdd1496f7, 0xa04620d3d0fc04a8, 0x1d50881230af9cc3, 0x53be287ded35f698, 0x673235793f7908e1, 
            0x46e91feb4535fbdc, 0x216c1524cbac57c0, 0x0a53eb08063a44df, 0x45f965b948778197, 0x6f2fa9d01ba03887, 
            0x60c57eba69ed4e15, 0x22c65ce977dd39cb, 0xa5d1ce0c5a7c6abf, 0xe8e26337cde13268, 0x0b4a575fdb6f8160, 
            0x400feb0bae786424, 0x633e0b621080bf50, 0x5a456e5a144e059b, 0xdc75548b5cd2e8cd, 0xdf9d76f766648113, 
            0x342bf8b7aec0de41, 0x831593e6b50ae928, 0x29e12b2a1872d7db, 0xb6362d8b640aec49, 0x2e78698eb5bba4a9, 
            0x9064494b8287afb9, 0x4c04974c6c1b4767, 0x5863b8685408be73, 0x0e8ca571066bc302, 0x088959d638956a37, 
            0x2e9392dfd5c30e86, 0x36da000d696e9d9e, 0x2a839b60548c1044, 0x3ebbaffcc5f270ca, 0x6da02738c0f92ee5, 
            0x962fd83157fe1682, 0x856dcc088cece014, 0xca8717351ab24cbd, 0x231527552d018184, 0x06793b14839607ec, 
            0xc54f89a7e193e5c1, 0xbacc209dd739707c, 0x7dc7053580f1ff20, 0x4ee696659cc1be91, 0xa3cb5d7769921646, 
            0x9c002aaa8a687ded, 0xc0c3a216563d9ae2, 0x035b6d98ee8a1b19, 0x68d89ab6ea60f57d, 0xec45ebfcc75a43fc, 
            0xc5baecd6bbbc6a26, 0x699d89305420574e, 0x48dce98c29e291a9, 0xb48e120ad1f9f23e, 0xe7c6368bd2aa145f, 
            0xcf6e7679e474e800, 0x3d55f9180cf7bd5a, 0xd07064c4f0125475, 0x9784173bc20bb2cf, 0xc3296df2c4be97be, 
            0x7ef38a3feaea3dcc, 0xa93ae5c3e3ac91b3, 0xc173a3156ae8e099, 0xa44373eaf0aff364, 0xb2a0bfb5000b2197, 
            0xa49a7367daa7357f, 0x6be7b09a41e8061b, 0xa78c4d974c96b3fb, 0x28f7fbded613a963, 0x294d2574459f8cca, 
            0xf3b457be6842a7ca, 0x9ce67b8b49364712, 0xd1b547099732fb15, 0x3538f30d9343b292, 0xc30c6e4c0dbee4c4, 
            0x90b83117f578872c, 0xee166f8ef6076653, 0x671a16f58b431a4d, 0xa272fd92ddc2c04e, 0xf2bf4fd243cb8c2d, 
            0xd2090a5c8c865eef, 0x7fd93d8b5401a273, 0x1ca67e32b0e47584, 0xb30ff462f8392fec, 0xb16ca64963ede86f, 
        ]

        result_host = Vector{UInt64}(result)

        for i = 1:n
            @test result_host[i] == xshr256_test_1[i]
        end
    end
    
    @testset "Xoshiro256++ validation: Second seed" begin
        n = 100
        result = CuArray{UInt64}(undef, n)

        CUDAnative.@sync begin
            @cuda threads=16 xoshiro256pp_gpu(0xa747f481346acb72, 0x8ad918349ab73966, 0xbec62b7cc97a0873, 0xf4975b3f04f272de, n, result)
        end

        # Seed 0xa747f481346acb72 0x8ad918349ab73966 0xbec62b7cc97a0873 0xf4975b3f04f272de:
        xshr256_test_2 = [
            0x8764a3205cb8bb19, 0x83430004f370c12d, 0x4b25f419b4c33798, 0x8a513a4e0cb13f7d, 0x838ec104e7520e51, 
            0x9d4e0fbd9efbd410, 0x4699cac599252763, 0x9d12a1920aa92ea6, 0x16f58890f28f73f0, 0xb9a3d53227a00f2a, 
            0x0a13b7dbe3e75ea8, 0x79ffcf5f0c8d1100, 0x99ece4fbeb7313dc, 0xc3f87b278b8ee4e1, 0x16a11441a19431e6, 
            0x67513ad840dac4c9, 0xc1e06281c8136e1c, 0x45fff01d45e28278, 0xbd34ecbec4c2dfd1, 0x8e1473a6621058bb, 
            0x5a4d7b7f47cd940d, 0xc1895931810f51e4, 0xe2da937313d1c62b, 0x2457af5f33bd5dc8, 0xeee84ffaf344e299, 
            0xba15cf4e32bdea22, 0xf6bdb5b21f9ec218, 0x1f57e7082a0e65e1, 0x0b0308f317319866, 0x9d7d1dd370af8c34, 
            0x6dcaa675fa0b21f7, 0x81f6098b1b7fd554, 0x10b95cf55f11840f, 0x2618e9ca09439e81, 0xe3365a6aad20217a, 
            0x91d9055d0163d663, 0x0e65d218a7775add, 0xd044ac77cd43fea5, 0x617118ea17e0b314, 0xc01d7ae0b8fa3785, 
            0xacbe5ba699d219e2, 0xe7e11d4508e32276, 0xbfb68436cc59c458, 0x0625ba7690a02a54, 0x94a9adb4ad8289c3, 
            0xfd9b4e6396f0b240, 0xb29486a69153d373, 0x541afedc53063ca5, 0x84b59a52889dddb7, 0x869d3adffcd07c97, 
            0x13a2a3363624c07f, 0x9a5db06194d2cd66, 0x588fc64b9737ed95, 0xe1c08df219eb64bb, 0x361074055893ede1, 
            0x9ca5480c4e77c5a8, 0x49f4b91279da85b3, 0xbb455871f21e0c38, 0x5ca49b23e994955b, 0xdb9261adea4fb9b6, 
            0x1f439d23db8369a5, 0x4b23e1a8a2b567f0, 0xf7f9b8afc8a989f4, 0x2eb334a70476a1d5, 0x473826fbd4e3a603, 
            0xf09a459b1860dd91, 0xc82e3ccb001f5a52, 0xd6cbdf410e30ce1d, 0x9b3bf1f29c0c524b, 0x896c2533de1e7e8a, 
            0x9cdad573ce10cde1, 0xbb084c48360588db, 0x6140567a93f1c7a8, 0x66f960c75ec1a817, 0x3e6de19b9f056c71, 
            0x3f563c8f3d00f8f2, 0xfa0db14f62a2aa2c, 0x4f085fd50a99a966, 0x9b4c8efdf3c99fb5, 0xbc18d391b6930fdc, 
            0x75cfbab414b7cb69, 0x4c0894009af8eea7, 0x945283b2b9824dc7, 0x9db7b027499d18ca, 0x37510bb9f0fefc6f, 
            0xfa2aceb93f756441, 0x604623f851ca0192, 0xebeeebf959db2c26, 0xb482490e0bdc79aa, 0x6ec59aa11bb8b941, 
            0xe000f1d2445876af, 0x3810a2f6e9ca3e49, 0x54434cd018715317, 0xd243f33a759bc4ca, 0xb7859923fe236fb3, 
            0x20d77e1aced47630, 0x31f0224fc82805e7, 0xcc6b181f051b66d0, 0x3c10226521a38a2c, 0x7a740af5acd8d654, 
        ]

        result_host = Vector{UInt64}(result)

        for i = 1:n
            @test result_host[i] == xshr256_test_2[i]
        end
    end

    @testset "Generate PRNG from thread and block indices" begin
        threads = 128
        blocks = 8

        n = threads * blocks
        values_dev = CuArray{Float32}(undef, n)

        CuArrays.@sync begin
            @cuda threads=threads blocks=blocks prng_from_thread_and_block_gpu(values_dev, n)
        end

        values_host = Vector{Float32}(values_dev)
        values_set = Set{Float32}(values_host)

        # This ensures that each element in `values_dev` is different from all
        # other elements.
        @test length(values_set) == n
    end
end