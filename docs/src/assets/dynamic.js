
async function getText(url) {
    let f = await fetch(url);
    let text = await f.text();
    return text
}

async function readOutput(name, upstream_vars) {
    // Drop extension regex; thanks to https://stackoverflow.com/questions/25351184.
    const rx = /\.[^/.]+$/;
    output_dir = window.location.href.replace(rx, "");
    upstream_vars_part = upstream_vars.join('/');
    const url = output_dir + `/${name}/${upstream_vars_part}.html`;
    console.log('url: ' + url);
    var output = await getText(url);
    console.log('output: ' + output);
    return output;
}

/**
  * Replace the content of an output which depends on `@bind` variables.
  * @param string id [identifier which identifies the output cell for variable `id`.]
  * @param {async string} output [Output text as obtained via `readOutput`].
  */
async function replaceVariable(id, output) {
    const text = await output;
    const el = document.getElementById('var-' + id);
    console.log(el);
    el.outerHTML = text;
}

var output = readOutput('c', ['1', '3'])
replaceVariable('c', output);

