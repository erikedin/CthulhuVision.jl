module BVH

using CthulhuVision.Light
using CthulhuVision.Random
using CthulhuVision.Materials
using CthulhuVision.Worlds
using CthulhuVision.Math

using StaticArrays
using CUDAnative

export Hitable, BVHNode, BVHAcceleration, AABB
export buildacceleration, hitacceleration

struct AABB
    min::Vector3
    max::Vector3

    function AABB(v1::Vector3, v2::Vector3, v3::Vector3)
        mini = Vector3(
            min(v1.x, v2.x, v3.x),
            min(v1.y, v2.y, v3.y),
            min(v1.z, v2.z, v3.z),
        )
        maxi = Vector3(
            max(v1.x, v2.x, v3.x),
            max(v1.y, v2.y, v3.y),
            max(v1.z, v2.z, v3.z),
        )

        new(mini, maxi)
    end

    function AABB(box1::AABB, box2::AABB)
        mini = Vector3(
            min(box1.min.x, box2.min.x),
            min(box1.min.y, box2.min.y),
            min(box1.min.z, box2.min.z),
        )
        maxi = Vector3(
            max(box1.max.x, box2.max.x),
            max(box1.max.y, box2.max.y),
            max(box1.max.z, box2.max.z),
        )
        new(mini, maxi)
    end

    function AABB()
        new(Vector3(0f0, 0f0, 0f0), Vector3(0f0, 0f0, 0f0))
    end
end

@inline function hitbox(aabb::AABB, ray::Ray, tmin::Float32, tmax::Float32) :: Bool
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

# Data structures:
# Hitable:
#   Contains enough data an object to use in BVH building. Contains:
#   - A bounding box
#   - An index to the owning triangle mesh
#   - An index to the triangle inside the mesh
struct Hitable
    box::AABB
    triangleindex::UInt32
    instanceindex::UInt32
end


# BVHNode:
#   Is a node in the hierarchical BVH tree. Is either a leaf node or a parent node.
#   - Bounding box
#   - Mesh index/left index
#   - Triangle index/right index

struct BVHNode
    box::AABB
    left::UInt32
    right::UInt32

    function BVHNode(hitable::Hitable)
        left = hitable.instanceindex | 0x8000_0000
        right = hitable.triangleindex
        new(hitable.box, left, right)
    end

    function BVHNode(nodes::Vector{BVHNode}, leftindex::UInt32, rightindex::UInt32)
        leftbox = nodes[leftindex].box
        rightbox = nodes[rightindex].box
        box = AABB(leftbox, rightbox)
        new(box, leftindex, rightindex)
    end

    function BVHNode()
        new(AABB(), UInt32(0), UInt32(0))
    end
end

@inline isleaf(node::BVHNode) = (node.left & 0x8000_0000) == 1
@inline getinstanceindex(node::BVHNode) = node.left & 0x7FFF_FFFF
@inline gettriangleindex(node::BVHNode) = node.right

# BVHAcceleration:
#   Contains all accelration data and can be ask if it was hit.
#   Contains only enough information to find the leaf triangle index, but does
#   not contain the triangle data itself. It must be used in conjuction with a World
#   object.
#   Contains:
#   - A list of BVHNodes

struct BVHAcceleration
    nodes::CuDeviceArray{BVHNode, 1, CUDAnative.AS.Global}
end

# VisitationStack is a stack wrapper around a thread local array
#   - array: A thread local array of fixed size
#   - len: length
#   Methods:
#       + push!: a node index
#       + pop!: a node index
mutable struct VisitationStack
    array::MVector{30, UInt32}
    len::UInt32

    VisitationStack() = new(zeros(MVector{30, UInt32}), 0)
end

@inline function pushnode!(s::VisitationStack, index::UInt32)
    s.len += 1
    @inbounds s.array[s.len] = index
end

@inline function popnode!(s::VisitationStack) :: UInt32
    s.len -= 1
    @inbounds s.array[s.len + 1]
end

@inline isempty(s::VisitationStack) = s.len == 0

# Building root node algorithm:
# Input:
#   - List of all Hitables in the scene
#   - PRNG
# Output: A BVHAcceleration object
# Algorithm:
#   - If only one object, create a leaf node:
#       + Create leaf node with bounding box, triangle mesh index, triangle index
#       + Return leaf node
#   - Randomly decide on an axis to sort on
#   - Sort all input Hitables by its axis value (x, y, or z)
#   - Split in half
#   - Call itself recursively on left and right
#   - Create BVHNode with left and right
#   - Return BVHNode

function allocatebvhnode(nodes::Vector{BVHNode}) :: UInt32
    push!(nodes, BVHNode())
    length(nodes)
end

function allocatebvhnode(nodes::Vector{BVHNode}, node::BVHNode) :: UInt32
    push!(nodes, node)
    length(nodes)
end

function buildbvhnode(hitables::AbstractVector{Hitable}, nodes::Vector{BVHNode}, start::UInt32, last::UInt32, rng::UniformRNG) :: UInt32
    isthisaleaf = start == last
    if isthisaleaf
        hitable = hitables[start]
        leafindex = allocatebvhnode(nodes, BVHNode(hitable))
        leafindex
    else
        # Allocate an empty node for this parent node, so it
        # ends up in the list before the children. That way, the first
        # node is the root node.
        thisindex = allocatebvhnode(nodes)

        # Choose axis randomly to sort by.
        axischoice = next(rng)
        byaxis = if axischoice < 0.33f0
            h -> h.box.min.x
        elseif axischoice < 0.66f0
            h -> h.box.min.y
        else
            h -> h.box.min.z
        end

        # Sort the hitables vector from start to last, based on the randomly
        # chosen axis above.
        hitablesview = view(hitables, start:last)
        sort!(hitablesview, by=byaxis)

        # Split the remaining nodes into two parts
        n = last - start + 1
        leftlast = UInt32(start + ceil(UInt32, n / 2) - 1)
        rightstart = UInt32(leftlast + 1)

        # Recursively create the child nodes.
        leftindex = buildbvhnode(hitables, nodes, start, leftlast, rng)
        rightindex = buildbvhnode(hitables, nodes, rightstart, last, rng)

        # Finally create the parent node and write it to the pre-allocated
        # node index.
        thisnode = BVHNode(nodes, leftindex, rightindex)
        nodes[thisindex] = thisnode

        thisindex
    end
end

function buildacceleration(hitables::AbstractVector{Hitable}, rng::UniformRNG) :: AbstractVector{BVHNode}
    nodes = Vector{BVHNode}()

    buildbvhnode(hitables, nodes, UInt32(1), UInt32(length(hitables)), rng)

    nodes
end

# Hit algorithm:
# Input:
#   - Ray
#   - BVHAcceleration
#   - World
#   - VisitationStack
# Output: HitRecord  
#
# Algorithm:
#   - Store nearest hit, initialized to none
#   - While local list is not empty:
#       - Get next node
#       - If leaf node:
#           + If is a hit, based on bounding box:
#               * Has mesh index and triangle index
#               * Get transformed Triangle from World
#               * If Triangle is hit by Ray:
#                   - If nearer than so far, store as nearest hit
#       - If parent node:
#           + If is a hit:
#               * Push index to left node
#               * Push index to right node
#   - Return nearest hit record

@inline function hitacceleration(acceleration::BVHAcceleration, tmin::Float32, tmax::Float32, ray::Ray, world::World) :: HitRecord
    visit = VisitationStack()
    pushnode!(visit, UInt32(1))

    rec = HitRecord()

    while !isempty(visit)
        # Get the next BVHNode to visit.
        thisindex = popnode!(visit)
        node = acceleration.nodes[thisindex]

        if hitbox(node.box, ray, tmin, tmax)
            if isleaf(node)
                instanceindex = getinstanceindex(node)
                triangleindex = gettriangleindex(node)
                triangle = gettriangle(world, instanceindex, triangleindex)
                trianglerec = hittriangle(triangle, tmin, tmax, ray)

                # Store the hit if it was closer than the current closest hit.
                if trianglerec.ishit && trianglerec.t < rec.t
                    rec = trianglerec
                end
            else
                pushnode!(visit, node.left)
                pushnode!(visit, node.right)
            end
        end
    end

    rec
end

end