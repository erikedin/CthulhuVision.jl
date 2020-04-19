module Math

export Vec3, len, unit, dot, randominunitsphere, squaredlength, cross, lenhost, unithost

using CUDAnative
using CthulhuVision.Random

struct Vec3
    x::Float32
    y::Float32
    z::Float32
end

@inline Base.:+(a::Vec3, b::Vec3) :: Vec3 = Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
@inline Base.:-(a::Vec3, b::Vec3) :: Vec3 = Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
@inline Base.:-(a::Vec3) :: Vec3 = Vec3(-a.x, -a.y, -a.z)
@inline Base.:*(t::Float32, v::Vec3) :: Vec3 = Vec3(t*v.x, t*v.y, t*v.z)
@inline Base.:/(a::Vec3, t::Float32) :: Vec3 = Vec3(a.x / t, a.y / t, a.z / t)
@inline len(a::Vec3) = CUDAnative.sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
@inline lenhost(a::Vec3) = sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
@inline squaredlength(a::Vec3) :: Float32 = a.x*a.x + a.y*a.y + a.z*a.z

@inline dot(a::Vec3, b::Vec3) :: Float32 = a.x * b.x + a.y * b.y + a.z * b.z

@inline function cross(a::Vec3, b::Vec3) :: Vec3
    Vec3(
          a.y * b.z - a.z * b.y,
        -(a.x * b.z - a.z * b.x),
          a.x * b.y - a.y * b.x
    )
end

@inline function unit(a::Vec3) :: Vec3
    l = len(a)
    a / l
end

@inline function unithost(a::Vec3) :: Vec3
    l = lenhost(a)
    a / l
end

@inline function randominunitsphere(rng::UniformRNG) :: Vec3
    p = Vec3(1.0f0, 1.0f0, 1.0f0)

    while squaredlength(p) >= 1.0f0
        p = 2.0f0 * Vec3(next(rng), next(rng), next(rng))
    end

    p
end

end