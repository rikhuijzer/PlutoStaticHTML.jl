# Dynamic

```@raw html
<script>
console.log("ba")
</script>
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "1925947cac2b63a98b439324857fc2ce0879445346414887133cf01aeacb6bec"
    julia_version = "1.6.5"
-->
<pre><code class="language-julia">begin
	# Examples at https://juliapluto.github.io/sample-notebook-previews/PlutoUI.jl.html.
	using PlutoUI
end</code></pre>


<pre><code class="language-julia">@bind a Slider(2:0.1:100)</code></pre>
<bond def="a"><input type='range' min='1' max='981' value='1'></bond>

<pre><code class="language-julia">@bind b Slider([4, 5])</code></pre>
<bond def="b"><input type='range' min='1' max='2' value='1'></bond>

<pre><code class="language-julia">c = a + b</code></pre>
<pre class=pre_class><code class="code-output">6.0</code></pre>

<pre><code class="language-julia">d = c + 1</code></pre>
<pre class=pre_class><code class="code-output">7.0</code></pre>

<pre><code class="language-julia">@bind z Slider([1, 2])</code></pre>
<bond def="z"><input type='range' min='1' max='2' value='1'></bond>

<!-- PlutoStaticHTML.End -->
```
