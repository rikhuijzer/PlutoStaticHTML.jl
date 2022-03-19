# Body for `cell.output.body` of
# using PlutoUI
# f(x) = Base.inferencebarrier(x);
# with_terminal() do
#     @code_warntype f(1)
# end
body = raw"""
    <div style="display: inline; white-space: normal;">

        <script type="text/javascript" id="plutouiterminal">
            let txt = "MethodInstance for Main.workspace#4.f(::Int64)\n  from f(x) in Main.workspace#4 at /home/rik/git/blog/posts/notebooks/inference.jl#==#9dbfb7d5-7035-4ea2-a6c0-efa00e39e90f:1\nArguments\n  #self#[36m::Core.Const(Main.workspace#4.f)[39m\n  x[36m::Int64[39m\nBody[91m[1m::Any[22m[39m\n[90m1 ─[39m %1 = Base.getproperty(Main.workspace#4.Base, :inferencebarrier)[36m::Core.Const(Base.inferencebarrier)[39m\n[90m│  [39m %2 = (%1)(x)[91m[1m::Any[22m[39m\n[90m└──[39m      return %2\n\n"

            var container = html`
                <pre
                    class="PlutoUI_terminal"
                    style="
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
                    "
                ></pre>
            `
            try {
                const { default: AnsiUp } = await import("https://cdn.jsdelivr.net/gh/JuliaPluto/ansi_up@v5.1.0-es6/ansi_up.js");
                container.innerHTML = new AnsiUp().ansi_to_html(txt);
            } catch(e) {
                console.error("Failed to import/call ansiup!", e)
                container.innerText = txt
            }
            return container
        </script>
    </div>
    """

txt = strip(PlutoStaticHTML._extract_txt(body))
@test startswith(txt, "MethodInstance")
@test endswith(txt, "return %2")
@test contains(txt, '\n')

patched = PlutoStaticHTML._patch_with_terminal(body)
@test contains(patched, """<pre id="plutouiterminal">""")
