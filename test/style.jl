before = """
    <p>foo</p>
    <div class="admonition note"><p class="admonition-title">Note</p><p>This is a note.</p>
    </div>
    <p>bar</p>
    """

after = """
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
    """

@test PlutoStaticHTML._convert_admonitions(before) == after

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
