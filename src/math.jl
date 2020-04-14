module Math

export Vec3, length, unit

struct Vec3
    x::Float32
    y::Float32
    z::Float32
end

Base.:+(a::Vec3, b::Vec3) = Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:-(a::Vec3, b::Vec3) = Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
Base.:*(t::Float32, v::Vec3) = Vec3(t*v.x, t*v.y, t*v.z)
Base.:/(a::Vec3, t::Float32) = Vec3(a.x / t, a.y / t, a.z / t)
length(a::Vec3) = (a.x*a.x + a.y*a.y + a.z*a.z)^0.5f0

function unit(a::Vec3) :: Vec3
    l = length(a)
    a / l
end

end