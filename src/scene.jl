module Scenes

export Scene, SceneSettings, Instance

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Spheres

struct Instance
    sphereindex::UInt32
    transformindex::UInt32
end

struct SceneSettings
    ambientemission::RGB
end

struct Scene
    world::AbstractVector{Sphere}
    transforms::AbstractVector{Transform}
    instances::AbstractVector{Instance}
    settings::SceneSettings
end

end