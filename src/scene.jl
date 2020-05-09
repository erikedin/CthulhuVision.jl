module Scenes

export Scene, SceneSettings, SceneNode
export group, transform, buildworld

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

function transform(sphere::Sphere, t::Transform) :: Sphere
    center = t * sphere.center
    Sphere(center, sphere.radius, sphere.material)
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

function group(objects::AbstractVector{Sphere}) :: SceneNode
    SceneNode(identitytransform(), objects, Vector{SceneNode}())
end

struct Scene
    rootnode::SceneNode
    settings::SceneSettings
end

function visitscenenode(objects::Vector{Sphere}, node::SceneNode, currenttransform::Transform) :: Transform
    t = currenttransform * node.transform

    for sphere in node.objects
        s = transform(sphere, t)
        push!(objects, s)
    end

    t
end

function processnode(objects::Vector{Sphere}, node::SceneNode, currenttransform::Transform)
    t = visitscenenode(objects, node, currenttransform)

    for c in node.children
        processnode(objects, c, t)
    end
end

function buildworld(scene::Scene) :: AbstractVector{Sphere}
    objects = Vector{Sphere}()

    processnode(objects, scene.rootnode, identitytransform())

    objects
end
end