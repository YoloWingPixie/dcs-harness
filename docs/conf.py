import os
import sys

# -- Project information -----------------------------------------------------
project = "Harness"
author = "Harness Contributors"

# -- General configuration ---------------------------------------------------
extensions = [
    "sphinx.ext.githubpages",  # creates .nojekyll in output for GitHub Pages
    "sphinxcontrib.luadomain",
    "sphinx_lua",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------
html_theme = "alabaster"
html_static_path = ["_static"]

# -- sphinx-lua configuration -----------------------------------------------
# Point to the Lua source directory so sphinx-lua can discover files
lua_source_path = [os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))]

# Treat '---' EmmyLua docblocks as documentation, and respect private prefix
lua_source_encoding = "utf8"
lua_source_comment_prefix = "---"
lua_source_use_emmy_lua_syntax = True
lua_source_private_prefix = "_"

# The master toctree document.
master_doc = "index"


