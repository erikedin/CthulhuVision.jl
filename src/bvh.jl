module BVH

export AABB, hit

using CthulhuVision.Light
using CthulhuVision.Math

struct AABB
    min::Vec3
    max::Vec3
end

@inline function hit(aabb::AABB, ray::Ray, tmin::Float32, tmax::Float32) :: Bool
    inversedistancex = 1.0f0 / direction(ray).x
    tx0 = (aabb.min.x - origin(ray).x) * inversedistancex
    tx1 = (aabb.max.x - origin(ray).x) * inversedistancex
    if inversedistancex < 0.0f0
        tx0, tx1 = tx1, tx0
    end

    inversedistancey = 1.0f0 / direction(ray).y
    ty0 = (aabb.min.y - origin(ray).y) * inversedistancey
    ty1 = (aabb.max.y - origin(ray).y) * inversedistancey
    if inversedistancey < 0.0f0
        ty0, ty1 = ty1, ty0
    end

    inversedistancez = 1.0f0 / direction(ray).z
    tz0 = (aabb.min.z - origin(ray).z) * inversedistancez
    tz1 = (aabb.max.z - origin(ray).z) * inversedistancez
    if inversedistancez < 0.0f0
        tz0, tz1 = tz1, tz0
    end

    t0 = max(tx0, ty0, tz0)
    t1 = min(tx1, ty1, tz1)

    tmin < t0 < t1 < tmax
end

end