module Triangles

export Triangle, transform, hittriangle

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CUDAnative

struct Triangle
    a::Vector3
    b::Vector3
    c::Vector3
    material::Material
end

transform(tri::Triangle, form::Transform) :: Triangle = Triangle(form * tri.a, form * tri.b, form * tri.c, tri.material)

##########
# Device #
##########

@inline function maxdim(v::Vector3)
    if v.x > v.y
        if v.x > v.z
            0
        else
            2
        end
    else
        if v.y > v.z
            1
        else
            2
        end
    end
end

@inline function hittriangle(tri::Triangle, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    v0v1 = tri.b - tri.a
    v0v2 = tri.c - tri.a

    direct = unit(direction(ray))

    normal = unit(cross(v0v1, v0v2))
    nr = dot(normal, direct)

    # Very nearly parallel, so don't report a hit.
    if abs(nr) < 0.0001f0
        #@cuprintf("Nearly parallel  Ray %f %f %f    %f %f %f Triangle %f %f %f   %f %f %f    %f %f %f\n", origin(ray).x, origin(ray).y, origin(ray).z, direction(ray).x, direction(ray).y, direction(ray).z, tri.a.x, tri.a.y, tri.a.z, tri.b.x, tri.b.y, tri.b.z, tri.c.x, tri.c.y, tri.c.z)
        return HitRecord()
    end

    no = dot(normal, origin(ray))
    d = -dot(normal, tri.a)
    t = -(no + d) / nr

    if t < tmin || t > tmax
        #@cuprintf("normal %f %f %f   no %f   nr %f   d %f   t %f  Ray %f %f %f    %f %f %f Triangle %f %f %f   %f %f %f    %f %f %f\n", normal.x, normal.y, normal.z, no, nr, d, t, origin(ray).x, origin(ray).y, origin(ray).z, direction(ray).x, direction(ray).y, direction(ray).z, tri.a.x, tri.a.y, tri.a.z, tri.b.x, tri.b.y, tri.b.z, tri.c.x, tri.c.y, tri.c.z)
        return HitRecord()
    end

    p = origin(ray) + t * direct

    # Determine if p is inside the triangle.
    edge0 = tri.b - tri.a
    v0p = p - tri.a
    e0 = cross(edge0, v0p)

    edge1 = tri.c - tri.b
    v1p = p - tri.b
    e1 = cross(edge1, v1p)

    edge2 = tri.a - tri.c
    v2p = p - tri.c
    e2 = cross(edge2, v2p)

    # The hit point p is on the wrong side of one of the edges.
    if dot(e0, normal) < 0f0 || dot(e1, normal) < 0f0 || dot(e2, normal) < 0f0
        return HitRecord()
    end

    if nr > 0f0
        normal = -normal
    end

    HitRecord(t, p, normal, tri.material)
end

end