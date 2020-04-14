module Light

using CthulhuVision.Math

export Ray, origin, direction, pointat

struct Ray
    a::Vec3
    b::Vec3
end

origin(r::Ray) = r.a
direction(r::Ray) = r.b
pointat(r::Ray, t::Float32) = r.a + t*r.b

end