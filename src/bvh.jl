module BVH

using CthulhuVision.Light

using StaticArrays
using CUDAnative

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

#
# BVHNode:
#   Is a node in the hierarchical BVH tree. Is either a leaf node or a parent node.
#   - Bounding box
#   - Mesh index/left index
#   - Triangle index/right index
#
# BVHAcceleration:
#   Contains all accelration data and can be ask if it was hit.
#   Created on the host but used by the device.
#   Contains only enough information to find the leaf triangle index, but does
#   not contain the triangle data itself. It must be used in conjuction with a World
#   object.
#   Contains:
#   - A list of BVHNodes

# VisitationStack is a stack wrapper around a thread local array
#   - array: A thread local array of fixed size
#   - len: length
#   Methods:
#       + push!: a node index
#       + pop!: a node index
mutable struct VisitationStack
    array::MVector{30, UInt32}
    len::UInt32
end

@inline function push!(s::VisitationStack, index::UInt32)
    s.len += 1
    @inbounds s.array[s.len] = index
end

@inline function pop!(s::VisitationStack) :: UInt32
    s.len -= 1
    @inbounds s.array[s.len + 1]
end

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
#
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

end