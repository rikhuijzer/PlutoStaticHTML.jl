sha(s) = bytes2hex(sha256(s))
path2sha(path::AbstractString) = sha(read(path))

"""
    State(input_sha::String, julia_version::String)

State obtained from a Pluto notebook file (".jl") where

- `input_sha`: SHA checksum calculated over the file
- `julia_version`: \\\$VERSION
"""
struct State
    input_sha::String
    julia_version::String
end

"""
    State(text::AbstractString)

Create a new State from a Pluto notebook file (".jl").
"""
State(text::AbstractString) = State(sha(text), string(VERSION))

function n_cache_lines()
    # Determine length by using `string(state::State)`.
    state = State("a", "b")
    lines = split(string(state), '\n')
    return length(lines)
end

const STATE_IDENTIFIER = "[PlutoStaticHTML.State]"

function string(state::State)::String
    return """
        <!--
            # This information is used for caching.
            $STATE_IDENTIFIER
            input_sha = "$(state.input_sha)"
            julia_version = "$(state.julia_version)"
        -->
        """
end

"Extract State from a HTML file which contains a State as string somewhere."
function extract_state(html::AbstractString)::State
    sep = '\n'
    lines = split(html, sep)
    start = findfirst(contains(STATE_IDENTIFIER), lines)::Int
    stop = start + 2
    info = join(lines[start:stop], sep)
    entries = parsetoml(info)["PlutoStaticHTML"]["State"]
    return State(entries["input_sha"], entries["julia_version"])
end

"Convert a notebook at `path` to a State."
function path2state(path::AbstractString)::State
    @assert endswith(path, ".jl")
    code = read(path, String)
    State(code)
end
