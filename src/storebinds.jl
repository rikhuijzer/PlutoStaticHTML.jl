"""
Write the bind outputs `nbo` to disk inside `dir` so that the outputs can be made available on a static website.

Originally, this functionality was planned to use HTTP Range requests.
See, for example,
https://phiresky.github.io/blog/2021/hosting-sqlite-databases-on-github-pages/.
All files would be stored in one big file and HTTP Range requests would request only specific information from a certain byterange.
However, storing to files actually makes more sense for multiple reasons:

1. It's simpler
1. It allows people requesting certain data via a sort of API.
    For the binary, people would need to know the index of certain information.
    With files, people would only need to know the logic behind the file paths.
1. May be more compact.
    The binary would need to pad every element to the same size to allow requesting the right range from the binary blob.
    This padding would require a lot of space.
1. Not all static site hosters allow HTTP Range requests.
    All of them do allow hosting files.
1. More involved strategies for authentication could be possible by setting permissions on folders.
    Setting permissions on binary blob ranges is uncommon, but setting permissions of folders common.
1. Once an initial connection to a domain is made, subsequent requests don't require handshaking and such.
    For subsequent requests, the time difference between reading from a large binary blob or a new file is mostly bound by network speed.
    File IO is an order of magnitude lower than network speed, so the difference between a new file lookup or an in memory loaded file range request shouldn't be very noticeable.

This would generate a large number of files.
Luckily, nowadays, storing 10k files isn't that big of a deal anymore.
For example, the CloudFlare Pages free plan allows for storing 20k files and the Git tree for the Linux Kernel contains 48k files.
"""
function _storebinds(dir, nbo::NotebookBindOutputs, hopts::HTMLOptions)
    # Remember that bindoutputs are outputs for cells which depend on binds.
    K = collect(keys(nbo.bindoutputs))
    for bindoutputs_key::Base.UUID in K
        bo::BindOutputs = nbo.bindoutputs[bindoutputs_key]
        name_sym = _var(uuid2cell(nbo.nb, bo.name))
        upstream_binds_syms = _var.(uuid2cell.(Ref(nbo.nb), bo.upstream_binds))
        # This way, the output is always the same and can be used as an API.
        sorted_upstream = sort(collect(upstream_binds_syms))

        # Stores the values at <name_sym>/<value.key[1]>/.../<value.key[n]>
        # So, the filename is the same as the last value in the key.
        # This format is compressed and requires readers to know which output
        # depends on which binds.
        # The mapping/index can be stored in a separate file later.
        # Sort here is for debugging purposes.
        for values_key in sort(collect(keys(bo.values)))
            output::Pluto.CellOutput = bo.values[values_key]
            # Dir which stores the output files.
            subdirs = values_key[1:end-1]
            output_dir = isempty(subdirs) ?
                joinpath(dir, string(name_sym)) :
                joinpath(dir, string(name_sym), string.(subdirs...))
            # This is called multiple times per dir, may need optimization.
            mkpath(output_dir)
            html = _output2html(output.body, output.mime, hopts)
            filename = string(values_key[end])::String
            path = joinpath(output_dir, filename)
            println("Writing $path")
            write(path, html)
        end
    end
end
