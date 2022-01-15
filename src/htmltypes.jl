"""
Based on Gumbo.jl.
Not using Gumbo because it is not worth the dependency.
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

