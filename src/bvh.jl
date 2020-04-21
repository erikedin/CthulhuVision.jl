module BVH

export AABB, hit, bvhbuilder, BVHNode, BVHWorld, TraversalList, isleaf, left

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

    t0 = max(tx0, ty0, tz0, tmin)
    t1 = min(tx1, ty1, tz1, tmax)

    t0 < t1
end

@inline function boundingbox(sphere::Sphere) :: AABB
    r = Vec3(sphere.radius, sphere.radius, sphere.radius)
    AABB(sphere.center - r, sphere.center + r)
end

@inline function surroundingbox(c::AABB, d::AABB) :: AABB
    small = Vec3(
        min(c.min.x, d.min.x),
        min(c.min.y, d.min.y),
        min(c.min.z, d.min.z))

    big = Vec3(
        max(c.max.x, d.max.x),
        max(c.max.y, d.max.y),
        max(c.max.z, d.max.z),
    )

    AABB(small, big)
end

@inline function boundingbox(spheres::AbstractArray{Sphere}) :: AABB
    box = AABB(
        Vec3(Inf32, Inf32, Inf32),
        Vec3(-Inf32, -Inf32, -Inf32)
    )

    for sphere in spheres
        box = surroundingbox(box, boundingbox(sphere))
    end

    box
end

#
# TraversalList is a wrapper around a fixed size array.
# It keeps track of which nodes to visit in the BVH structure.
#

mutable struct TraversalList
    array::CuDeviceArray{UInt32, 1, CUDAnative.AS.Shared}
    offset::UInt32
    len::UInt32

    TraversalList(array::CuDeviceArray{UInt32, 1, CUDAnative.AS.Shared}, offset::UInt32) = new(array, offset, 0)
end

@inline function add!(trav::TraversalList, v::UInt32)
    trav.len += 1
    @inbounds trav.array[trav.offset + trav.len] = v
end
@inline function remove!(trav::TraversalList) :: UInt32
    trav.len -= 1
    @inbounds trav.array[trav.offset + trav.len + 1]
end
@inline isempty(trav::TraversalList) :: Bool = trav.len == 0

#
# BVHNode is a node in the tree structure we build to accelerate
# the hit function.
# It keeps track of a bounding box, which contains all its children
# and a pointer to the left and right child node.
#

struct BVHNode
    box::AABB
    left::UInt32
    right::UInt32
end

@inline function leafnode(sphere::Sphere, index::UInt32) :: BVHNode
    leafindex = 0x8000_0000 | index
    box = boundingbox(sphere)

    BVHNode(box, leafindex, 0x0000_0000)
end

@inline function parentnode(leftindex::UInt32, left::BVHNode, rightindex::UInt32, right::BVHNode) :: BVHNode
    box = surroundingbox(left.box, right.box)
    left = 0x7FFF_FFFF & leftindex
    right = 0x7FFF_FFFF & rightindex

    BVHNode(box, left, right)
end

@inline isleaf(n::BVHNode) :: Bool = n.left & 0x80000000 != 0
@inline left(n::BVHNode) :: UInt32 = n.left & 0x7FFFFFFF
@inline right(n::BVHNode) :: UInt32 = n.right & 0x7FFFFFFF

function allocatebvhnode(nodes::Vector{BVHNode}) :: Int
    n = BVHNode(
        AABB(Vec3(-1.0f0, -2.0f0, -3.0f0), Vec3(0.0f0, 0.0f0, 0.0f0)),
        0,
        0
    )
    push!(nodes, n)
    length(nodes)
end

function makebvhnode(spheres::Vector{Tuple{UInt32, Sphere}}, start::UInt32, last::UInt32, rng::UniformRNG, nodes::Vector{BVHNode}) :: UInt32
    axischoice = next(rng)
    byaxis = if axischoice < 0.33f0
        s -> s[2].center.x - s[2].radius
    elseif axischoice < 0.66f0
        s -> s[2].center.y - s[2].radius
    else
        s -> s[2].center.z - s[2].radius
    end

    thisindex = allocatebvhnode(nodes)

    isleaf = start == last
    if isleaf
        sphereindex = spheres[start][1]
        sphere = spheres[start][2]
        node = leafnode(sphere, sphereindex)
        nodes[thisindex] = node
    else
        sphereview = view(spheres, start:last)
        sort!(sphereview, by=byaxis)

        # There's two or more left.
        n = last - start + 1
        leftlast = UInt32(start + ceil(UInt32, n / 2) - 1)
        rightstart = UInt32(leftlast + 1)

        leftindex = makebvhnode(spheres, start, leftlast, rng, nodes)
        leftnode = nodes[leftindex]
        rightindex = makebvhnode(spheres, rightstart, last, rng, nodes)
        rightnode = nodes[rightindex]

        node = parentnode(leftindex, leftnode, rightindex, rightnode)
        nodes[thisindex] = node
    end

    thisindex
end

function bvhbuilder(spheres::AbstractArray{Sphere}, rng::UniformRNG) :: AbstractVector{BVHNode}
    nodes = Vector{BVHNode}()

    sphereswithindex = Vector{Tuple{UInt32, Sphere}}(
        [Tuple{UInt32, Sphere}((UInt32(i), s))
         for (i, s) in enumerate(spheres)]
    )

    makebvhnode(sphereswithindex, UInt32(1), UInt32(length(sphereswithindex)), rng, nodes)

    nodes
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