# Dynamic

```@raw html
<script>
console.log("ba")
</script>
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

<!-- PlutoStaticHTML.End -->
```
