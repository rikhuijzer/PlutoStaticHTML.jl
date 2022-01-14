# Dynamic

```@raw html
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "cb3dbe95143895e712426a128f0d666d8ed1a79e090620f056649c4450638cae"
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
<pre><code class="code-output">5</code></pre>

<!-- PlutoStaticHTML.End -->

<script>
console.log("bar")
</script>

```
