module Triangles

export Triangle, transform, hittriangle

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials

struct Triangle
    a::Point
    b::Point
    c::Point
end

transform(tri::Triangle, form::Transform) :: Triangle = Triangle(form * tri.a, form * tri.b, form * tri.c)

##########
# Device #
##########

@inline function hittriangle(t::Triangle, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    HitRecord()
end

end