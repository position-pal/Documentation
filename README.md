# Project documentation

To view locally the website:

```
hugo server -D
```

When pushed the changes are deployed automatically on [`position-pal.github.io`](https://position-pal.github.io/).

## Structure

```plaintext
.
├── README.md
├── archetypes
│   └── default.md                        a template file for new content
├── content
│   ├── docs                              folder containing website pages
│   │   └── requirements                  a nested section in the website
│   │       ├── _index.md
│   │       ├── context-map.md
│   │       └── knoledge-crunching.md
|   |   └── ...
│   ├── res                               folder containing images
│   │   └── context-map.png
|   |   └── ...
│   └── schemas                           folder containing schemas (UML, ...)
│       └── context-map.cml
|       └── ...
├── data
│   └── landing.yaml                      landing page configuration
├── go.mod
├── go.sum
├── hugo.yaml                             theme configuration
```

- `content` folder contains the documentation sources:
  - `docs` folder contains the documentation markdown pages
    - :point_right: **To write a new file: `hugo new <MD_FILE>` (example: `hugo new docs/requirements/context-map.md`)**
    - For nested sections write a `_index.md` like [this one](./content/docs/requirements/_index.md)
    - [Hugo shortcuts](https://gohugo.io/content-management/shortcodes/) and [custom theme ones](https://lotusdocs.dev/docs/shortcodes/) can be useful
    - :warning: `draft` pages are not deployed
  - `schemas` folder contains the schemas (`.cml`, `.puml`)
    - Mermaid schemas are rendered automatically inside the markdown :)
  - `res` folder contains images
- `data/landing.yaml` contains the [landing page configuration](https://lotusdocs.dev/docs/guides/landing-page/)
- `hugo.yaml` contains the [theme configurations](https://lotusdocs.dev/docs/reference/configuration/)
- more information can be found [here](https://lotusdocs.dev/docs/overview/)
