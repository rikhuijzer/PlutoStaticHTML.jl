const show_richest_override = quote
    PlutoRunner.is_mime_enabled(::MIME"application/vnd.pluto.tree+object") = false
    PlutoRunner.is_tree_viewer_enabled(::MIME"text/plain") = false
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
    $(format_output_exception_override)
end

# These overrides are used when `use_distributed=false`.
eval(show_richest_override)
eval(format_output_exception_override)

