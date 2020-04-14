module Light

using CthulhuVision.Math

export Ray, RGB, origin, direction, pointat

struct RGB
    r::Float32
    g::Float32
    b::Float32
end

struct Ray
    a::Vec3
    b::Vec3
end

@inline origin(r::Ray) = r.a
@inline direction(r::Ray) = r.b
@inline pointat(r::Ray, t::Float32) = r.a + t*r.b

end