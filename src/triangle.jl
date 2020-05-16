module Triangles

using CthulhuVision.Math

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