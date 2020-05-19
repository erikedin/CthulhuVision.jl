module Worlds

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

export World, gettriangle, MeshTriangle, MeshInstance

using CthulhuVision.Math
using CthulhuVision.Triangles
using CthulhuVision.Materials
using CUDAnative

struct MeshTriangle
    vertex1::UInt32
    vertex2::UInt32
    vertex3::UInt32
end

struct MeshInstance
    meshindex::UInt32
    material::Material
    tform::Transform
end

struct World
    vertexes::CuDeviceArray{Vector3, 1, CUDAnative.AS.Global}
    meshtriangles::CuDeviceArray{MeshTriangle, 1, CUDAnative.AS.Global}
    instances::CuDeviceArray{MeshInstance, 1, CUDAnative.AS.Global}
end

@inline function gettriangle(world::World, instanceindex::UInt32, triangleindex::UInt32) :: Triangle
    @inbounds instance = world.instances[instanceindex]
    @inbounds meshtriangle = world.meshtriangles[triangleindex]
    @inbounds v1 = instance.tform * world.vertexes[meshtriangle.vertex1]
    @inbounds v2 = instance.tform * world.vertexes[meshtriangle.vertex2]
    @inbounds v3 = instance.tform * world.vertexes[meshtriangle.vertex3]

    Triangle(v1, v2, v3, instance.material)
end

end