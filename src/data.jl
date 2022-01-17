"""
Write the bind outputs `nbo` to disk inside `dir` so that the outputs can be made available on a static website.

Originally, this functionality was planned to use HTTP Range requests.
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
    Setting persmissions on binary blob ranges is uncommon, but setting permissions of folders is often allowed.
"""
function writefiles(dir, nbo::NotebookBindOutputs, hopts::HTMLOptions)
    # Remember that bindoutputs are outputs for cells which depend on binds.
    K = collect(keys(nbo.bindoutputs))
    for bindoutputs_key::Base.UUID in K
        bo::BindOutputs = nbo.bindoutputs
        _cell2html(cell, hopts)
    end
end
