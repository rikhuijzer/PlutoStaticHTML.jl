"""
Based on Gumbo.jl.
Not using Gumbo because it is not worth the dependency.

Note that Pluto always starts the range at 1 and has step size 1.
"""
struct HTMLInput{T}
    attributes::Dict{String,String}
end

function attribute(s::AbstractString)::Union{Missing,Pair{String,String}}
    cleaner = strip(s, ['<', '>'])
    keyvalue = split(cleaner, '=')
    if length(keyvalue) == 2
        key, value = keyvalue
        return string(key)::String => string(strip(value, '\''))::String
    else
        return missing
    end
end

function HTMLInput(html::AbstractString)
    @assert startswith(html, "<bond ")
    input_rx = r"<input[^>]*>"
    m = match(input_rx, html)
    input_text = string(m.match)::String
    A = attribute.(split(input_text, ' '))
    attributes = Dict(skipmissing(A)...)
    type = Symbol(pop!(attributes, "type"))
    return HTMLInput{type}(Dict(attributes...))
end

"""
Based on the HTTP range specification.
Currently ignores `autocomplete` and `list`.
"""
struct HTTPRange <: HTTPElement
    min::Float64
    max::Float64
    step::Float64
    value::Float64
end

function _get_float(attributes::Dict{String,String}, key::String, default::Float64)::Float64
    value = get(attributes, key, default)::Union{String,Float64}
    return value isa String ? parse(Float64, value) : value
end

function HTTPRange(A::Dict{String,String})
    min = _get_float(A, "min", 0.0)
    max = _get_float(A, "max", 100.0)
    step = _get_float(A, "step", 1.0)
    value = _get_float(A, "value", 1.0)
    return HTTPRange(min, max, step, value)
end

"Drop any kwargs which are not a fieldname of `T`."
function _drop_extra(T::Type, kwargs::Dict)::Dict{Symbol,String}
    copy = Dict(kwargs)
    @show copy
    names = string.(collect(fieldnames(T)))
    @show names
    for key in keys(kwargs)
        @show key
        @assert typeof(key) == eltype(names)
        if !(key in names)
            pop!(copy, key)
        end
    end
    K = Symbol.(keys(copy))
    V = values(copy)
    return Dict(zip(K, V))
end

HTTPRange(input::HTMLInput{:range}) = HTTPRange(input.attributes)

