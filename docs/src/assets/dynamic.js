
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

/* Read output for output variable `name::string` with a vector of upstream variable values. */
async function readOutputFromValues(name, upstream_values) {
    const upstream_vals_part = upstream_values.join('/');
    const url = relative(`${name}/${upstream_vals_part}.html`);
    const output = await getText(url);
    return output;
}

/* Return current value for `bindvar`. */
function readBindValue(bindvar) {
    const binds = document.querySelectorAll('bond');
    for (i in binds) {
        const bind = binds[i];
        if (bind.attributes.def.value === bindvar) {
            const inputElement = bind.children[0];
            return inputElement.value;
        }
    }
    return -1;
}

/* Read output for output variable `name::string` with a vector of upstream variable names. */
async function readOutputFromVariables(name, upstream_vars) {
    const upstream_values = upstream_vars.map(function(upstream_var) {
        return readBindValue(upstream_var);
    });
    return await readOutputFromValues(name, upstream_values);
}

/* Parse a line, such as "c/$a/$b". */
function parseIndexLine(line) {
    const elements = line.split('/'); // [ 'c', '$a', '$b' ]
    const key = elements[0]; // 'c'
    const binds = elements.slice(1); // [ '$a', '$b' ]
    const binds_vars = binds.map(s => s.replace('$', '')); // [ 'a', 'b' ]
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
    el.outerHTML = text;
}

/* Add `oninput` events to all binds (HTML inputs). */
async function addOnInputEvents() {
    const binds = document.querySelectorAll('bond');
    binds.forEach(function(bind) {
        const bindvar = bind.attributes.def.textContent;
        const inputElement = bind.children[0];
        const action = `bindChangeEvent('${bindvar}')`;
        inputElement.setAttribute('onchange', action);
    });
}

var mapping = readIndex();

async function bindChangeEvent(bindvar) {
    outputs_index = await mapping;
    for (const [outputvar, upstream_binds] of Object.entries(outputs_index)) {
        // Update the output variables which depend on `bindvar`.
        if (upstream_binds.includes(bindvar)) {
            const value = await readOutputFromVariables(outputvar, upstream_binds);
            replaceVariable(outputvar, value);
        }
    }
}

// This is to trigger one of the async calls.
var output = readOutputFromValues('c', ['1', '2']);

addOnInputEvents();

