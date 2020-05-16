module Scenes

using CthulhuVision.Light
using CthulhuVision.Triangles

struct SceneSettings
    ambientemission::RGB
end

struct Scene
    objects::AbstractVector{Triangle}
    settings::SceneSettings
end

end