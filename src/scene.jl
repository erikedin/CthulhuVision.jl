module Scenes

export Scene, SceneSettings, SceneNode
export group, transform

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Spheres

struct SceneSettings
    ambientemission::RGB
end

struct SceneNode
    transform::Transform
    objects::AbstractVector{Sphere}
    children::AbstractVector{SceneNode}
end

function transform(objects::AbstractVector{Sphere}, t::Transform) :: SceneNode
    SceneNode(t, objects, Vector{Sphere}())
end

function transform(children::AbstractVector{SceneNode}, t::Transform) :: SceneNode
    SceneNode(t, Vector{Sphere}(), children)
end

function group(children::AbstractVector{SceneNode}) :: SceneNode
    SceneNode(identitytransform(), Vector{Sphere}(), children)
end

struct Scene
    rootnode::SceneNode
    settings::SceneSettings
end

end