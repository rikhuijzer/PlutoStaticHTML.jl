sha(s) = bytes2hex(sha256(s))
path2sha(path::AbstractString) = sha(read(path))

struct State
    input_sha::String
    julia_version::String
end

State(html::AbstractString) = State(sha(html), VERSION)

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

