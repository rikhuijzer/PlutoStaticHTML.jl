before = """
    <p>foo</p>
    <div class="admonition note">
        <p class="admonition-title">Note</p>
        <p>This is a note.</p>
    </div>
    <p>bar</p>
    """

after = """
    <!DOCTYPE >
    <HTML>
    <head></head>
    <body>
    <p>foo</p>
    <div class="admonition is-note">
    <header class="admonition-header">
    Note
    </header>
    <div class="admonition-body">
    <p>This is a note.</p>
    </div>
    </div>
    <p>bar</p>
    </body>
    </HTML>
    """

expected = replace(after, '\n' => "")

@test PlutoStaticHTML._convert_admonitions(before) == expected

nb = Notebook([
    Cell("""
        md\"\"\"
        !!! note
            This is a note.
        \"\"\"
        """)
])
use_distributed = false
html, _ = notebook2html_helper(nb; use_distributed)
# This tests that there has been a hit on the `_convert_admonition` replacer.
@test contains(html, "admonition-header")

# https://github.com/rikhuijzer/PlutoStaticHTML.jl/issues/148.
before = """
    <div class="markdown">
        <div class="admonition info">
            <p class="admonition-title">This is how the Error we expect here looks like</p>
            <pre><code>DomainError with 0.0: Lorem</code></pre>
    </div>
    </div>
    """

after = """
    <div class="markdown"><div class="admonition is-info">
      <header class="admonition-header">
        This is how the Error we expect here looks like
      </header>
      <div class="admonition-body">
        <pre><code>DomainError with 0.0:
        Lorem</code></pre>
    </div>
      </div>
    </div>
    """

@test PlutoStaticHTML._convert_admonition(before) == after

nb = Notebook([
    Cell("""
        function pretty_error(err)
            Markdown.parse(\"\"\"
            !!! info "This is how the Error we expect here looks like"
                ```
                \$(replace(sprint(showerror, err), "\n" => "\n        "))
                ```
            \"\"\")
        end
        """),
    Cell("""pretty_error(DomainError(0.0, "Lorem"))""")
])

html, _ = notebook2html_helper(nb; use_distributed)
@test contains(html, "admonition-header")
