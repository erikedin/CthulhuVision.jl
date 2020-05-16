module Triangles

export Triangle, transform, hit

using CthulhuVision.Math
using CthulhuVision.Light

struct Triangle
    a::Point
    b::Point
    c::Point
end

transform(tri::Triangle, form::Transform) :: Triangle = Triangle(form * tri.a, form * tri.b, form * tri.c)

##########
# Device #
##########

@inline function hit(t::Triangle, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    
    rec
end

end