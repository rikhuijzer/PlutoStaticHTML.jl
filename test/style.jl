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


# TODO: Add test starting from MD.
