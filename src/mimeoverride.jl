const CONFIG_PLUTORUNNER = """
    PlutoRunner.is_mime_enabled(::MIME"application/vnd.pluto.table+object") = false
    PlutoRunner.PRETTY_STACKTRACES[] = false
"""

# These overrides are used when `use_distributed=false`.
eval(CONFIG_PLUTORUNNER)
