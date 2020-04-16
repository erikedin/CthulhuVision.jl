module Random

export uniform32, SplitMix64, Xoshiro256pp, next

@inline function uniform32(x::UInt64) :: Float32
    fract = UInt32((x >> 41) & 0b0_0000_0000_1111_1111_1111_1111_1111_111)
    k = (fract | 0b0_0111_1111_0000_0000_0000_0000_0000_000)
    reinterpret(Float32, k) - 1.0f0
end

# SplitMix64 is based on the description in http://prng.di.unimi.it/splitmix64.c
# and validated against 200 test vectors produced by that code.

mutable struct SplitMix64
    x::UInt64
end

@inline function next(sm::SplitMix64) :: UInt64
    sm.x += 0x9e3779b97f4a7c15
    z = sm.x
    z = (xor(z, z >> 30)) * 0xbf58476d1ce4e5b9
    z = (xor(z, z >> 27)) * 0x94d049bb133111eb

    xor(z, z >> 31)
end

# Xoshiro256++ is based on the description in http://prng.di.unimi.it/xoshiro256plusplus.c
# and validated against 200 test vectors produced by that code.

mutable struct Xoshiro256pp
    s0::UInt64
    s1::UInt64
    s2::UInt64
    s3::UInt64
end

@inline function rotl(x::UInt64, k::Int) :: UInt64
    (x << k) | (x >> (64 - k))
end

@inline function next(r::Xoshiro256pp) :: UInt64
    result = rotl(r.s0 + r.s3, 23) + r.s0

    t = r.s1 << 17
    r.s2 = xor(r.s2, r.s0)
    r.s3 = xor(r.s3, r.s1)
    r.s1 = xor(r.s1, r.s2)
    r.s0 = xor(r.s0, r.s3)

    r.s2 = xor(r.s2, t)
    r.s3 = rotl(r.s3, 45)

    result
end

end