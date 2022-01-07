sha(s) = bytes2hex(sha256(s))
path2sha(path::AbstractString) = sha(read(path))

struct State
    input_sha::String
    julia_version::String
end

"Create a new State from a HTML file."
State(html::AbstractString) = State(sha(html), string(VERSION))

function string(state::State)::String
    return """
        <!--
            # This information is used for caching.
            [PlutoStaticHTML.State]
            input_sha = "$(state.input_sha)"
            julia_version = "$(state.julia_version)"
        -->
        """
end

"Extract State from a HTML file which contains a State as string somewhere."
function extract_state(html::AbstractString)::State
    sep = '\n'
    lines = split(html, sep)
    start = findfirst(contains("[PlutoStaticHTML.State]"), lines)
    stop = start + 2
    info = join(lines[start:stop], sep)
    entries = parsetoml(info)["PlutoStaticHTML"]["State"]
    return State(entries["input_sha"], entries["julia_version"])
end
