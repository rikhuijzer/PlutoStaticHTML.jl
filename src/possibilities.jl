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

"""
"""

"Parse `<select>`."
function _selectpossibilities(html::AbstractString)::UnitRange{Int}
    1:2
end

"""
Based on the HTTP range specification.
Currently ignores `autocomplete` and `list`.
"""
struct HTMLRange
    min::Float64
    max::Float64
    step::Float64
    value::Float64
end

function _get_float(attributes::Dict{String,String}, key::String, default::Float64)::Float64
    value = get(attributes, key, default)::Union{String,Float64}
    return value isa String ? parse(Float64, value) : value
end

function HTMLRange(A::Dict{String,String})
    min = _get_float(A, "min", 0.0)
    max = _get_float(A, "max", 100.0)
    step = _get_float(A, "step", 1.0)
    value = _get_float(A, "value", 1.0)
    return HTMLRange(min, max, step, value)
end

HTMLRange(input::HTMLInput{:range}) = HTMLRange(input.attributes)

function _inputpossibilities(html)::UnitRange{Int}
    input_rx = r"<input[^>]*>"
    m = match(input_rx, html)
    input_text = string(m.match)::String
    A = attribute.(split(input_text, ' '))
    attributes = Dict(skipmissing(A)...)
    type = Symbol(pop!(attributes, "type"))
    input = HTMLInput{type}(Dict(attributes...))
    r = HTMLRange(input)
    floatrange = range(r.min, r.max; step=r.step)
    # PlutoUI generated HTML always starts at 1.
    return 1:length(floatrange)
end

"""
    _possibilities(html::AbstractString) -> AbstractRange

Return all the possible values for a HTML control element such as `<select>` or `<input>`.
Note that Pluto converts any Julia input type into 1, 2, ..., n for `n` input values.
This is because HTML cannot hold arbitrary Julia objects.

We only need to save the HTML values because Pluto converts them to Julia values inside `set_bond_values_reactive`.
"""
function _possibilities(html::AbstractString)::UnitRange{Int}
    @assert startswith(html, "<bond ")
    if contains(html, "<select")
        return _selectpossibilities(html)
    else
        return _inputpossibilities(html)
    end
end

