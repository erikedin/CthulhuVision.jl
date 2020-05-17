module Math

export Vector3, Point, len, unit, dot, randominunitsphere, squaredlength, cross, lenhost, unithost, Transform
export identitytransform, translation, rotation, permute

using CUDAnative
using CthulhuVision.Random

struct Vector3
    x::Float32
    y::Float32
    z::Float32
end

@inline Base.:+(a::Vector3, b::Vector3) :: Vector3 = Vector3(a.x + b.x, a.y + b.y, a.z + b.z)
@inline Base.:-(a::Vector3, b::Vector3) :: Vector3 = Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
@inline Base.:-(a::Vector3) :: Vector3 = Vector3(-a.x, -a.y, -a.z)
@inline Base.:*(t::Float32, v::Vector3) :: Vector3 = Vector3(t*v.x, t*v.y, t*v.z)
@inline Base.:/(a::Vector3, t::Float32) :: Vector3 = Vector3(a.x / t, a.y / t, a.z / t)
@inline len(a::Vector3) = CUDAnative.sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
@inline lenhost(a::Vector3) = sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
@inline squaredlength(a::Vector3) :: Float32 = a.x*a.x + a.y*a.y + a.z*a.z

@inline dot(a::Vector3, b::Vector3) :: Float32 = a.x * b.x + a.y * b.y + a.z * b.z

@inline function cross(a::Vector3, b::Vector3) :: Vector3
    Vector3(
          a.y * b.z - a.z * b.y,
        -(a.x * b.z - a.z * b.x),
          a.x * b.y - a.y * b.x
    )
end

@inline function unit(a::Vector3) :: Vector3
    l = len(a)
    a / l
end

@inline function unithost(a::Vector3) :: Vector3
    l = lenhost(a)
    a / l
end

@inline function byindex(v::Vector3, index) :: Float32
    if index == 0
        v.x
    elseif index == 1
        v.y
    else
        v.z
    end
end

@inline permute(v::Vector3, x, y, z) :: Vector3 = Vector3(byindex(v, x), byindex(v, y), byindex(v, z))

@inline function randominunitsphere(rng::UniformRNG) :: Vector3
    p = Vector3(1.0f0, 1.0f0, 1.0f0)

    while squaredlength(p) >= 1.0f0
        p = 2.0f0 * Vector3(next(rng), next(rng), next(rng)) - Vector3(1f0, 1f0, 1f0)
    end

    p
end

#
# Point
#

struct Point
    x::Float32
    y::Float32
    z::Float32
end

@inline function byindex(p::Point, index) :: Float32
    if index == 0
        p.x
    elseif index == 1
        p.y
    else
        p.z
    end
end

@inline Base.:-(p::Point, v::Vector3) :: Point = Point(p.x - v.x, p.y - v.y, p.z - v.z)
@inline Base.:-(a::Point, b::Point) :: Vector3 = Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
@inline Base.:+(a::Point, b::Vector3) :: Point = Point(a.x + b.x, a.y + b.y, a.z + b.z)
@inline Base.abs(p::Point) :: Point = Point(abs(p.x), abs(p.y), abs(p.z))
@inline permute(p::Point, x, y, z) :: Point = Point(byindex(p, x), byindex(p, y), byindex(p, z))
@inline dot(a::Vector3, b::Point) :: Float32 = a.x * b.x + a.y * b.y + a.z * b.z

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

@inline function Base.:*(a::Transform, b::Vector3) :: Vector3
    w = 0f0
    x = a.e11 * b.x + a.e12 * b.y + a.e13 * b.z + a.e14 * w
    y = a.e21 * b.x + a.e22 * b.y + a.e23 * b.z + a.e24 * w
    z = a.e31 * b.x + a.e32 * b.y + a.e33 * b.z + a.e34 * w

    Vector3(x, y, z)
end

@inline function Base.:*(a::Transform, b::Point) :: Point
    w = 1f0
    x = a.e11 * b.x + a.e12 * b.y + a.e13 * b.z + a.e14 * w
    y = a.e21 * b.x + a.e22 * b.y + a.e23 * b.z + a.e24 * w
    z = a.e31 * b.x + a.e32 * b.y + a.e33 * b.z + a.e34 * w

    Point(x, y, z)
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

function rotation(θ::Float32, axis::Vector3) :: Transform
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