const CONFIG_PLUTORUNNER = string(quote
        PlutoRunner.is_mime_enabled(::MIME"application/vnd.pluto.tree+object") = false
        PlutoRunner.PRETTY_STACKTRACES[] = false
    end)::String

# These overrides are used when `use_distributed=false`.
eval(CONFIG_PLUTORUNNER)
