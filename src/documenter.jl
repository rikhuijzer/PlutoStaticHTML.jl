"""
Return path to the notebook starting with "/docs/src/".
The "/docs/src/" assumption is required since we don't know the module.
"""
function _relative_notebook_path(bopts::BuildOptions, in_path::String)::Union{String,Nothing}
    absolute_path = joinpath(bopts.dir, in_path)
    pos = findfirst("/docs/src/", absolute_path)
    if !isnothing(pos)
        relative_path = absolute_path[first(pos) + 1:end]
        return string(relative_path)
    else
        return nothing
    end
end

function _editurl_text(
        bopts::BuildOptions,
        github_repo::String,
        branch::String,
        in_path::String
    )
    path = _relative_notebook_path(bopts, in_path)
    url = "https://github.com/$github_repo/blob/$branch/$path"
    return """
        ```@meta
        EditURL = "$url"
        ```
        """
end

function _editurl_text(bopts::BuildOptions, in_path::String)::String
    github_repo = get(ENV, "GITHUB_REPOSITORY", "")
    if github_repo != ""
        # Only when we're in GitHub's CI, it is possible to figure out the path to the file.
        # "refs/heads/$(branchname)" for branch, "refs/tags/$(tagname)" for tags.
        # Thanks to Documenter for this comment.
        github_ref = get(ENV, "GITHUB_REF", "")
        if github_ref != ""
            prefix = "refs/heads/"
            if contains(github_ref, prefix)
                branch = github_ref[length(prefix) + 1:end]
                return _editurl_text(bopts, github_repo, branch, in_path)
            else
                # We're on a tag so maybe that's a triggered deploy for stable docs?
                branch = "main"
                return _editurl_text(bopts, github_repo, branch, in_path)
            end
        else
            @warn "github_ref was empty which is unexpected"
            return ""
        end
    else
        return ""
    end
end

"""
Return raw_html where Markdown headers hidden in the HTML are converted back to Markdown so that Documenter parses them.
"""
function _fix_header_links(html::String)
    rx = r"""<div class="markdown"><h2>([^<]*)<\/h2>"""
    substitution_string = s"""
            ```
            ## \1
            ```@raw html
            <div class="markdown">
            """
    return replace(html, rx => substitution_string)
end
