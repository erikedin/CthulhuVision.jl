module BVH

export AABB, hit, bvhbuilder, BVHNode, BVHWorld, TraversalList

using CuArrays
using CUDAnative

using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Materials
using CthulhuVision.Spheres
import CthulhuVision.Spheres: hit

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

mutable struct TraversalList
    array::CuDeviceArray{UInt32, 1, CUDAnative.AS.Global}
    len::UInt32

    TraversalList(array::CuDeviceArray{UInt32, 1, CUDAnative.AS.Global}) = new(array, 0)
end

@inline function add!(trav::TraversalList, v::UInt32)
    trav.len += 1
    @inbounds trav.array[trav.len] = v
end
@inline function remove!(trav::TraversalList) :: UInt32
    trav.len -= 1
    @inbounds trav.array[trav.len + 1]
end
@inline isempty(trav::TraversalList) :: Bool = trav.len == 0


struct BVHNode
    box::AABB
    left::UInt32
    right::UInt32
end

@inline isleaf(n::BVHNode) :: Bool = n.left & 0x80000000 != 0
@inline left(n::BVHNode) :: UInt32 = n.left & 0x7FFFFFFF
@inline right(n::BVHNode) :: UInt32 = n.right & 0x7FFFFFFF

function bvhbuilder(spheres::AbstractArray{Sphere}, rng::UniformRNG) :: AbstractVector{BVHNode}
    Vector{BVHNode}([
        BVHNode(
            AABB(Vec3(-5.0f0, -3.0f0, -102.0f0), Vec3(5.0f0, 3.0f0, -98.0f0)),
            0x80_00_00_01,
            0x00_00_00_00,
        )
    ])
end

struct BVHWorld
    bvhs::CuDeviceArray{BVHNode, 1, CUDAnative.AS.Global}
    world::CuDeviceArray{Sphere, 1, CUDAnative.AS.Global}
    traversal::TraversalList
end

@inline function hit(bvh::BVHWorld, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    rec = HitRecord()
    add!(bvh.traversal, 0x00_00_00_01)

    while !isempty(bvh.traversal)
        nodeindex = remove!(bvh.traversal)

        @inbounds node = bvh.bvhs[nodeindex]
        if hit(node.box, ray, tmin, tmax)
            if isleaf(node)
                sphereindex = left(node)
                @inbounds sphere = bvh.world[sphereindex]
                thisrec = hit(sphere, tmin, tmax, ray)
                if thisrec.t < rec.t
                    rec = thisrec
                end
            else
                add!(bvh.traversal, left(node))
                add!(bvh.traversal, right(node))
            end
        end
    end

    rec
end

end