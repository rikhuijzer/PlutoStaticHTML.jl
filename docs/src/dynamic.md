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
<pre id='c' class='pre_class'><code class='code-output'>5</code></pre>

<pre><code class="language-julia">d = c + 1</code></pre>
<pre id='d' class='pre_class'><code class='code-output'>6</code></pre>

<!-- PlutoStaticHTML.End --><script type='text/javascript'>
    async function getText(url) {
        let f = await fetch(url);
        let text = await f.text();
        return text
    }
    async function process() {
        output_dir = window.location.href.replace(/\.[^/.]+$/, "")
        const url = output_dir + '/c/1/1.html';
        console.log('url: ' + url);
        var output = await getText(url);
        console.log('output: ' + output);
        const el = document.getElementById('d');
        console.log(el);
    }
    process()
</script>

```
