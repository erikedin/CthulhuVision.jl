module Math

export Vec3, len, unit, dot, randominunitsphere, squaredlength, cross, lenhost, unithost, Transform
export identitytransform, translation, rotation

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

#
# Transformation matrix 4x4
#

struct Transform
    e11::Float32
    e12::Float32
    e13::Float32
    e14::Float32
    e21::Float32
    e22::Float32
    e23::Float32
    e24::Float32
    e31::Float32
    e32::Float32
    e33::Float32
    e34::Float32
    e41::Float32
    e42::Float32
    e43::Float32
    e44::Float32
end

@inline function Base.:*(a::Transform, b::Transform) :: Transform
    e11 = a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31 + a.e14 * b.e41
    e12 = a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32 + a.e14 * b.e42
    e13 = a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33 + a.e14 * b.e43
    e14 = a.e11 * b.e14 + a.e12 * b.e24 + a.e13 * b.e34 + a.e14 * b.e44

    e21 = a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31 + a.e24 * b.e41
    e22 = a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32 + a.e24 * b.e42
    e23 = a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33 + a.e24 * b.e43
    e24 = a.e21 * b.e14 + a.e22 * b.e24 + a.e23 * b.e34 + a.e24 * b.e44

    e31 = a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31 + a.e34 * b.e41
    e32 = a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32 + a.e34 * b.e42
    e33 = a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33 + a.e34 * b.e43
    e34 = a.e31 * b.e14 + a.e32 * b.e24 + a.e33 * b.e34 + a.e34 * b.e44

    e41 = a.e41 * b.e11 + a.e42 * b.e21 + a.e43 * b.e31 + a.e44 * b.e41
    e42 = a.e41 * b.e12 + a.e42 * b.e22 + a.e43 * b.e32 + a.e44 * b.e42
    e43 = a.e41 * b.e13 + a.e42 * b.e23 + a.e43 * b.e33 + a.e44 * b.e43
    e44 = a.e41 * b.e14 + a.e42 * b.e24 + a.e43 * b.e34 + a.e44 * b.e44

    Transform(
        e11, e12, e13, e14,
        e21, e22, e23, e24,
        e31, e32, e33, e34,
        e41, e42, e43, e44,
    )
end

@inline function Base.:*(a::Transform, b::Vec3) :: Vec3
    w = 1f0
    x = a.e11 * b.x + a.e12 * b.y + a.e13 * b.z + a.e14 * w
    y = a.e21 * b.x + a.e22 * b.y + a.e23 * b.z + a.e24 * w
    z = a.e31 * b.x + a.e32 * b.y + a.e33 * b.z + a.e34 * w

    Vec3(x, y, z)
end

########
# Host #
########

function identitytransform() :: Transform
    Transform(
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
        0f0, 0f0, 0f0, 1f0,
    )
end

function translation(x::Float32, y::Float32, z::Float32) :: Transform
    Transform(
        1f0, 0f0, 0f0, x,
        0f0, 1f0, 0f0, y,
        0f0, 0f0, 1f0, z,
        0f0, 0f0, 0f0, 0f0,
    )
end

function rotation(θ::Float32, axis::Vec3) :: Transform
    u = unithost(axis)

    e11 = cos(θ) + u.x*u.x*(1f0 - cos(θ))
    e12 = u.x * u.y * (1f0 - cos(θ)) - u.z * sin(θ)
    e13 = u.x * u.z * (1f0 - cos(θ)) + u.y * sin(θ)
    e14 = 0f0

    e21 = u.y * u.x * (1f0 - cos(θ)) + u.z * sin(θ)
    e22 = cos(θ) + u.y * u.y * (1f0 - cos(θ))
    e23 = u.y * u.z * (1f0 - cos(θ)) - u.x * sin(θ)
    e24 = 0f0

    e31 = u.z * u.x * (1f0 - cos(θ)) - u.y * sin(θ)
    e32 = u.z * u.y * (1f0 - cos(θ)) + u.x * sin(θ)
    e33 = cos(θ) + u.z * u.z * (1f0 - cos(θ))
    e34 = 0f0

    e41 = 0f0
    e42 = 0f0
    e43 = 0f0
    e44 = 1f0

    Transform(
        e11, e12, e13, e14,
        e21, e22, e23, e24,
        e31, e32, e33, e34,
        e41, e42, e43, e44,
    )
end

end