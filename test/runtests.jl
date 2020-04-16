using Test
using CthulhuVision.Random: uniform32, SplitMix64, next

@testset "CthulhuVision.Random" begin
    @testset "uniform32 is 0.0f0 <= x < 1.0f0" begin
        ks = [uniform32(x) for x in rand(UInt64, 1000)] 
        for k in ks
            @test 0.0f0 <= k < 1.0f0
        end
    end

    @testset "SplitMix64 validation" begin
        # These test values were generated from the C code available at
        # http://prng.di.unimi.it/splitmix64.c
        # 2020-04-16

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
        sm1 = SplitMix64(0x0000000000000000)
        for i = 1:length(fromseed0)
            @test next(sm1) == fromseed0[i]
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
        
        sm2 = SplitMix64(0x1234567890123456)
        for i = 1:length(fromseed123)
            @test next(sm2) == fromseed123[i]
        end
    end
end