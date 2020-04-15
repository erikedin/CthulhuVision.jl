module Math

export Vec3, length, unit, dot

using CUDAnative

struct Vec3
    x::Float32
    y::Float32
    z::Float32
end

@inline Base.:+(a::Vec3, b::Vec3) :: Vec3 = Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
@inline Base.:-(a::Vec3, b::Vec3) :: Vec3 = Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
@inline Base.:*(t::Float32, v::Vec3) :: Vec3 = Vec3(t*v.x, t*v.y, t*v.z)
@inline Base.:/(a::Vec3, t::Float32) :: Vec3 = Vec3(a.x / t, a.y / t, a.z / t)
@inline length(a::Vec3) = CUDAnative.sqrt(a.x*a.x + a.y*a.y + a.z*a.z)

@inline dot(a::Vec3, b::Vec3) :: Float32 = a.x * b.x + a.y * b.y + a.z * b.z

@inline function unit(a::Vec3) :: Vec3
    l = length(a)
    a / l
end

end