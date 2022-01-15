# Dynamic

```@raw html
<script>
console.log("ba")
</script>
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "442ac73b6dcc56c7c2b7fd97544a8ee29eff765a129bafab2fcc184831b39f5e"
    julia_version = "1.6.5"
-->
<pre><code class="language-julia">begin
	# Examples at https://juliapluto.github.io/sample-notebook-previews/PlutoUI.jl.html.
	using PlutoUI
end</code></pre>


<pre><code class="language-julia">@bind a Slider(1:3)</code></pre>
<bond def="a"><input type='range' min='1' max='3' value='1'></bond>

<pre><code class="language-julia">@bind b Slider([4, 5])</code></pre>
<bond def="b"><input type='range' min='1' max='2' value='1'></bond>

<pre><code class="language-julia">c = a + b</code></pre>
<pre class=documenter-example-output><code class="code-output">5</code></pre>

<pre><code class="language-julia">d = c + 1</code></pre>
<pre class=documenter-example-output><code class="code-output">6</code></pre>

<!-- PlutoStaticHTML.End -->
```
