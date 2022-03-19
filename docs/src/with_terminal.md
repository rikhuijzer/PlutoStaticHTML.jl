# `with_terminal`

`PlutoUI` has a well-known function `with_terminal` to show terminal output with a black background and colored text.
For example, when having loaded `PlutoUI` via `using PlutoUI`, the following code will show the text "Some terminal output" in a mini terminal window inside `Pluto`:

```julia
with_terminal() do
    println("Some terminal output")
end
```

This functionality is supported by `PlutoStaticHTML` too.
To make it work, `PlutoStaticHTML` takes the output from `Pluto`, which looks roughly as follows:

```html
<div style="display: inline; white-space: normal;">
    <script type="text/javascript" id="plutouiterminal">
        let txt = "Some terminal output"

        ...
    </script>
</div>
```

and changes it to:

```html
<pre id="plutouiterminal">
Some terminal output
</pre>
```

This output is now much simpler to style to your liking.
Below, there is an example style that you can apply which will style the terminal output just like it would in `Pluto`.

In terminals, the colors are enabled via so called ANSI escape codes.
These ANSI colors can be shown correctly by adding the following Javascript to the footer of your website.
This code will loop through all the HTML elements with `id="plutouiterminal"` and apply the `ansi_to_html` function to the body of those elements:

```html
<script type="text/javascript">
    async function color_ansi() {
        const terminalOutputs = document.querySelectorAll("[id=plutouiterminal]");
        // Avoid loading AnsiUp if there is no terminal output on the page.
        if (terminalOutputs.length == 0) {
            return
        };
        try {
            const { default: AnsiUp } = await import("https://cdn.jsdelivr.net/gh/JuliaPluto/ansi_up@v5.1.0-es6/ansi_up.js");
            const ansiUp = new AnsiUp();
            // Indexed loop is needed here, the array iterator doesn't work for some reason.
            for (let i = 0; i < terminalOutputs.length; ++i) {
                const terminalOutput = terminalOutputs[i];
                const txt = terminalOutput.innerHTML;
                terminalOutput.innerHTML = ansiUp.ansi_to_html(txt);
            };
        } catch(e) {
            console.error("Failed to import/call ansiup!", e);
        };
    };
    color_ansi();
</script>
```

Next, the output can be made more to look like an embedded terminal by adding the following to your CSS:

```css
#plutouiterminal {
  max-height: 300px;
  overflow: auto;
  white-space: pre;
  color: white;
  background-color: black;
  border-radius: 3px;
  margin-top: 8px;
  margin-bottom: 8px;
  padding: 15px;
  display: block;
  font-size: 14px;
}
```

!!! note
    Note that the Javascript code above downloads the `ansi_up.js` file from a content delivery network (CDN).
    This is not advised because CDNs are bad for privacy, may go offline and are bad for performance.
    They are bad for performance because browsers do not cache CDN downloaded content between different domains for security reasons.
    Therefore, CDN content will cause at least an extra DNS lookup in most cases.
