# Dynamic

```@raw html
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "0446517597cff6c4638ed63f57e6000aa57abdaca43f59bb47d2fc741cfa3c30"
    julia_version = "1.6.5"
-->
<pre><code class="language-julia">begin
	# Examples at https://juliapluto.github.io/sample-notebook-previews/PlutoUI.jl.html.
	using PlutoUI
end</code></pre>


<pre><code class="language-julia">@bind a html"&lt;input type=range min='2' max='3'&gt;"</code></pre>
<bond def="a"><input type=range min='2' max='3'></bond>

<pre><code class="language-julia">@bind b html"&lt;input type=range min='1' max='3'&gt;"</code></pre>
<bond def="b"><input type=range min='1' max='3'></bond>

<pre><code class="language-julia">c = a + b</code></pre>
<pre id='var-c' class='pre_class'><code class='code-output'>5</code></pre>

<pre><code class="language-julia">d = c + 1</code></pre>
<pre id='var-d' class='pre_class'><code class='code-output'>6</code></pre>

<!-- PlutoStaticHTML.End --><script type='text/javascript'>
    
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




</script>

```
