module Random

export uniform32, SplitMix64, next

function uniform32(x::UInt64) :: Float32
    fract = UInt32((x >> 41) & 0b0_0000_0000_1111_1111_1111_1111_1111_111)
    k = (fract | 0b0_0111_1111_0000_0000_0000_0000_0000_000)
    reinterpret(Float32, k) - 1.0f0
end

# SplitMix64 is based on the description in http://prng.di.unimi.it/splitmix64.c
# and validated against 200 test vectors produced from that code.

mutable struct SplitMix64
    x::UInt64
end

function next(sm::SplitMix64) :: UInt64
    sm.x += 0x9e3779b97f4a7c15
    z = sm.x
    z = (xor(z, z >> 30)) * 0xbf58476d1ce4e5b9
    z = (xor(z, z >> 27)) * 0x94d049bb133111eb

    xor(z, z >> 31)
end

end