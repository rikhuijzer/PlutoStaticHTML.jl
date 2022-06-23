# Putting the override in a expr because it needs to be evaluated in this process and the
# distributed process.
const show_richest_override = quote
    # Used inside this quote.
    using Markdown

    # Override for `show_richest`.
    # Override the full method because allmimes was replaced by the compiler.
    function PlutoRunner.show_richest(io::IO, @nospecialize(x))::Tuple{<:Any,MIME}
        nonplutomimes = filter(m -> !occursin("pluto.tree", string(m)), PlutoRunner.allmimes)
        # ugly code to fix an ugly performance problem
        local mime = nothing
        for m in nonplutomimes
            if PlutoRunner.pluto_showable(m, x)
                mime = m
                break
            end
        end

        if mime in PlutoRunner.imagemimes
            show(io, mime, x)
            nothing, mime
        elseif mime isa MIME"application/vnd.pluto.table+object"
            PlutoRunner.table_data(x, IOContext(io, :compact => true)), mime
        elseif mime isa MIME"text/latex"
            # Some reprs include $ at the start and end.
            # We strip those, since Markdown.LaTeX should contain the math content.
            # (It will be rendered by MathJax, which is math-first, not text-first.)
            texed = repr(mime, x)
            Markdown.html(io, Markdown.LaTeX(strip(texed, ('$', '\n', ' '))))
            nothing, MIME"text/html"()
        else
            # the classic:
            show(io, mime, x)
            nothing, mime
        end
    end
end

# Giving `val` back so that the stacktrace can be printed easily.
const format_output_exception_override = :(
    function PlutoRunner.format_output(val::CapturedException; context=PlutoRunner.default_iocontext)
        msg = sprint(PlutoRunner.try_showerror, val.ex)
        mime = MIME"application/vnd.pluto.stacktrace+object"()
        return (Dict{Symbol,Any}(:msg => msg, :stacktrace => val), mime)
    end
)

const OLD_PROCESS_PREAMBLE = WorkspaceManager.process_preamble()

# Override the preamble to disable Pluto's pretty printing.
WorkspaceManager.process_preamble() = quote
    $OLD_PROCESS_PREAMBLE
    $(show_richest_override)
    $(format_output_exception_override)
end

# Yes. These overrides are used when `use_distributed=false`.
eval(show_richest_override)
eval(format_output_exception_override)

