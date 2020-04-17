module Light

using CthulhuVision.Math

export Ray, RGB, origin, direction, pointat

struct RGB
    r::Float32
    g::Float32
    b::Float32
end

@inline Base.:*(t::Float32, rgb::RGB) :: RGB = RGB(t*rgb.r, t*rgb.g, t*rgb.b)
@inline Base.:/(rgb::RGB, t::Float32) :: RGB = RGB(rgb.r/t, rgb.g/t, rgb.b/t)
@inline Base.:+(a::RGB, b::RGB) :: RGB = RGB(a.r + b.r, a.g + b.g, a.b + b.b)

struct Ray
    a::Vec3
    b::Vec3
end

@inline origin(r::Ray) = r.a
@inline direction(r::Ray) = r.b
@inline pointat(r::Ray, t::Float32) = r.a + t*r.b

end