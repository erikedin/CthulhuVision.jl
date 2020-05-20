module Scenes

using CthulhuVision.Light
using CthulhuVision.Math
using CthulhuVision.Triangles
using CthulhuVision.Worlds
using CthulhuVision.Materials
using CthulhuVision.BVH

export Scene, SceneSettings, Mesh
export addmesh!, addinstance!

struct SceneSettings
    ambientemission::RGB
end

struct MeshLocation
    first::UInt32
    last::UInt32
end

struct Scene
    vertexes::Vector{Vector3}
    meshtriangles::Vector{MeshTriangle}
    meshes::Vector{MeshLocation}
    instances::Vector{MeshInstance}
    hitables::Vector{Hitable}
    settings::SceneSettings

    Scene(settings::SceneSettings) = new([], [], [], [], [], settings)
end

struct Mesh
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

function addmesh!(scene::Scene, mesh::Mesh) :: UInt32
    # MeshTriangle indexes are one-indexed when used as relative indexes inside a mesh.
    # Therefore, we offset all indexes by the existing length of the vertexes vector.
    vertexoffset = UInt32(length(scene.vertexes))
    append!(scene.vertexes, mesh.vertexes)

    meshtriangles = [offsetmeshtriangle(mt, vertexoffset) for mt in mesh.triangles]
    firstmeshtriangle = length(scene.meshtriangles) + 1
    lastmeshtriangle = firstmeshtriangle + length(meshtriangles) - 1
    append!(scene.meshtriangles, meshtriangles)

    location = MeshLocation(firstmeshtriangle, lastmeshtriangle)
    push!(scene.meshes, location)
    meshindex = length(scene.meshes)

    meshindex
end

function addinstance!(scene::Scene, instance::MeshInstance)
    push!(scene.instances, instance)
    instanceindex = length(scene.instances)

    # println("Instance transform: $(instance.tform)")
    # println("")

    # This tells us where all the triangle indexes are.
    locations = scene.meshes[instance.meshindex]

    for index = locations.first:locations.last
        meshtriangle = scene.meshtriangles[index]
        v1 = instance.tform * scene.vertexes[meshtriangle.vertex1]
        v2 = instance.tform * scene.vertexes[meshtriangle.vertex2]
        v3 = instance.tform * scene.vertexes[meshtriangle.vertex3]
        # println("World vertexes $v1    $v2    $v3")

        box = AABB(v1, v2, v3)

        # println("Mesh triangle: $index: $meshtriangle")
        # println("Box $box")

        hitable = Hitable(box, index, instanceindex)
        push!(scene.hitables, hitable)
    end

    # println("")
    # println("")
end

end