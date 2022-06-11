using HTTP: HTTP
using TOML: TOML

repo = "JuliaBinaryWrappers/tectonic_jll.jl"
version = "tectonic-v0.9.0+0"
url = "https://raw.githubusercontent.com/$repo/$(HTTP.escape(version))/Artifacts.toml"
@info "url: $url"

body!(r::HTTP.Response) = String(r.body)::String

r = HTTP.get(url)
# text = body!(r)

function toml_write(path, data::Dict)
    open(path, "w") do io
        TOML.print(io, data)
    end
end

function set_lazy(text::String)
    toml = TOML.parse(text)::Dict{String,Any}
    tectonic_toml = toml["tectonic"]
    new_entries = map(toml["tectonic"]) do entry
        entry["lazy"] = true
        return entry
    end
    new_toml = Dict{String,Any}("tectonic" => new_entries)
    return new_toml
end

new_toml = set_lazy(text)

path = joinpath(dirname(@__DIR__), "Artifacts.toml")
@info "Writing updated TOML to $path"
toml_write(path, new_toml)
@info "New contents of $path:\n$(read(path,String))"
return path
