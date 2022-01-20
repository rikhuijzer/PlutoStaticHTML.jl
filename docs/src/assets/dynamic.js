
async function getText(url) {
    let f = await fetch(url);
    let text = await f.text();
    return text;
}

/* Return path relative to current location with `suffix`. */
function relative(suffix) {
    // Drop extension regex; thanks to https://stackoverflow.com/questions/25351184.
    const rx = /\.[^/.]+$/;
    const current_path = window.location.href.replace(rx, "");
    const with_slash = suffix.startsWith('/') ? suffix : '/' + suffix
    return current_path + with_slash;
}

async function readOutput(name, upstream_vars) {
    const output_dir = relative('');
    console.log('output_dir: ' + output_dir);
    const upstream_vars_part = upstream_vars.join('/');
    const url = output_dir + `/${name}/${upstream_vars_part}.html`;
    console.log('url: ' + url);
    const output = await getText(url);
    return output;
}

/* Parse a line, such as "c/$a/$b". */
function parseIndexLine(line) {
    const elements = line.split('/'); // [ 'c', '$a', '$b' ]
    const key = elements[0]; // 'c'
    const binds = elements.slice(1); // [ '$a', '$b' ]
    const binds_vars = binds.map(s => s.replace('$', '')); // [ 'a', 'b' ]
    console.log('binds_vars: ' + binds_vars);
    return [key, binds_vars];
}

/**
 * Read and parse the outputs index.
 * The index is assumed to be at a path relative to the current page.
 */
async function readIndex() {
    const location = relative('outputs_index.txt');
    const html = await getText(location);
    const without_comments = html.replace(/<!--.*?-->/sg, "");
    const lines = without_comments.split('\n');
    const nonempty = lines.filter(String);
    const parsed = nonempty.map(parseIndexLine);
    var mapping = {};
    for (i in parsed) {
        const key = parsed[i][0];
        const binds_vars = parsed[i][1];
        mapping[key] = binds_vars;
    };
    return mapping;
}

/**
  * Replace the content of an output which depends on `@bind` variables.
  *
  * @param string id [identifier which identifies the output cell for variable `id`.]
  * @param {async string} output [Output text as obtained via `readOutput`].
  */
async function replaceVariable(id, output) {
    const text = await output;
    const el = document.getElementById('var-' + id);
    console.log(el);
    el.outerHTML = text;
}

var output = readOutput('c', ['1', '3']);
replaceVariable('c', output);

readIndex();
