module BVH

# Data structures:
# Hitable:
#   Contains enough data an object to use in BVH building. Contains:
#   - A bounding box
#   - An index to the owning triangle mesh
#   - An index to the triangle inside the mesh
#
# Vertex:
#   A 3D point. A Vector3? A Point? Vector3 until we fix all the Vector3/Point stuff
#   - x, y, z
#
# Triangle:
#   Is a triangle, with vertices in world space and material
#   - Vertex 1
#   - Vertex 2
#   - Vertex 3
#   - Material
#
# MeshTriangle:
#   Represents a triangle, but actually only indexes the vertices.
#   - Index to vertex 1
#   - Index to vertex 2
#   - Index to vertex 3
# 
# Mesh:
#   A triangle mesh.
#   - Transformation to be applied to the mesh
#   - Material
#   - Start index for MeshTriangles
#   - End index for MeshTriangles
#
# World:
#   Contains all triangle data in the entire scene.
#   - A list of vertices
#   - A list of MeshTriangles
#   - A list of Mesh's
#   Methods:
#   - gettriangle: Get Triangle in world space
#       Input:
#           - World
#           - Mesh index
#           - Triangle index
#       + Get mesh from mesh index
#       + Get transform from mesh
#       + Get material from mesh
#       + Get MeshTriangle from triangle index
#       + Get vertices from MeshTriangles indexes
#       + Transform vertices into world space using
#       + Return Triangle with transformed vertices and material
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
#
# VisitationStack:
#   A stack wrapper around a thread local array
#   - A thread local array of fixed size
#   - Size
#   Methods:
#       + push: a node index
#       + pop: a node index
#
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