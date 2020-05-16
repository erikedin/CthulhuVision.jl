module Scenes

using CthulhuVision.Light
using CthulhuVision.Triangles

export Scene, SceneSettings

struct SceneSettings
    ambientemission::RGB
end

struct Scene
    objects::AbstractVector{Triangle}
    settings::SceneSettings
end

end