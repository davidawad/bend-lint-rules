# Showcase

One screenshot, real `blr lint` output on a generic fixture
([`fixtures/dead/def/fail_transitive`](../fixtures/dead/def/fail_transitive)): a chain of defs that only
call each other is reported whole.

![dead/def on a chain of dead defs](showcase/dead-def.png)

Reproduce it (needs `just setup`, a built `blr`, and ImageMagick; the font defaults to macOS Menlo, override with `FONT=/path/to.ttf`):

```sh
just setup
docs/showcase/make-screenshots.sh
```

The script writes the captured text to `docs/showcase/dead-def.txt` and renders it to `docs/showcase/dead-def.png`.
