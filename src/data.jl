
"Convert nbo to raw data and return indexes to the outputs"
function data(nbo::NotebookBindOutputs, hopts::HTMLOptions)
    # Remember that bindoutputs are outputs for cells which depend on binds.
    K = collect(keys(nbo.bindoutputs))
    for bindoutputs_key::Base.UUID in K
        bo::BindOutputs = nbo.bindoutputs
        _cell2html(cell, hopts)
    end
end
