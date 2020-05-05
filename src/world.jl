module Worlds

# World is a GPU-appropriate representation of the scene.
# While Scene is a tree structure, the World is a linear structure that can be
# easily copied to the GPU.

export Instance

using CthulhuVision.Math
using CthulhuVision.Scenes
using CthulhuVision.Spheres

struct Instance
    objectindex::UInt32
    transformindex::UInt32
end

struct World
    objects::Vector{Sphere}
    transforms::Vector{Transform}
    instances::Vector{Instance}

    World() = new(Vector{Sphere}(), Vector{Transform}(), Vector{Instance}())
end

function visitscenenode(world::World, node::SceneNode, currenttransform::Transform) :: Transform
    t = currenttransform * node.transform
    push!(world.transforms, t)
    transformindex = length(world.transforms)
    for o in node.objects
        push!(world.objects, o)
        objectindex = length(world.objects)
        # TODO So with this description of a Scene, with a Sphere as an object in a tree,
        # we actually make a single instance per sphere, which half defeats the purpose.
        # We do get multiple uses of a single transform, which is half the purpose of
        # instances, but we'd like to be able to describe a scene where a single Sphere
        # object was reused in several places.
        instance = Instance(objectindex, transformindex)
        push!(world.instances, instance)
    end

    t
end

function processnode(world::World, node::SceneNode, currenttransform::Transform)
    t = visitscenenode(world, node, currenttransform)

    for c in node.children
        processnode(world, node, t)
    end
end

function buildworld(scene::Scene) :: World
    world = World()

    processnode(world, scene.rootnode, identitytransform())

    world
end

end