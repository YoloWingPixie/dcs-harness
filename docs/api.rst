API Reference
=============

This section will surface the Lua API from source using sphinx-lua.

Notes
-----

- The configuration in ``conf.py`` enables EmmyLua docblock parsing from the ``src/`` directory.
- As we progressively add or refine docblocks, we can include specific modules/functions using the Lua domain directives.

Examples (to be expanded)
-------------------------

.. rubric:: Lua Domain Examples

.. code-block:: rst

   .. lua:function:: GetUnit(unitName)
      :noindex:

      Returns a unit by name if it exists; otherwise returns ``nil``.

   .. lua:module:: harness
      :noindex:

      A virtual module placeholder for grouping global helpers in the docs.


