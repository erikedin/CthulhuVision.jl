module Scenes

using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Triangles
using CthulhuVision.World
using CthulhuVision.Materials

export Scene, SceneSettings

struct SceneSettings
    ambientemission::RGB
end

struct Scene
    vertexes::Vector{Vector3}
    meshtriangles::Vector{MeshTriangle}
    meshes::Vector{Mesh}

    Scene() = new([], [], [])
end

struct HostMesh
    material::Material
    vertexes::Vector{Vector3}
    triangles::Vector{MeshTriangle}
end

function offsetmeshtriangle(mt::MeshTriangle, vertexoffset::UInt32) :: MeshTriangle
    MeshTriangle(
        mt.vertex1 + vertexoffset,
        mt.vertex2 + vertexoffset,
        mt.vertex3 + vertexoffset
    )
end

function addvertices!(scene::Scene, mesh::HostMesh)
    # MeshTriangle indexes are one-indexed when used as relative indexes inside a mesh.
    vertexoffset = UInt32(length(scene.vertexes))
    append!(scene.vertexes, mesh.vertexes)

    meshtriangles = [offsetmeshtriangle(mt, vertexoffset) for mt in mesh.triangles]
    append!(scene.meshtriangles, meshtriangles)
end

function addinstance!(scene::Scene, hostmesh::HostMesh, tform::Transform)
    mesh = Mesh(hostmesh.materil, tform)
    push!(scene.meshes, mesh)
end

end