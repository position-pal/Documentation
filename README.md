# Project documentation

To view locally the website:

```
hugo server -D
```

When pushed the changes are deployed automatically on [`position-pal.github.io`](https://position-pal.github.io/).

## Structure

- `content` folder contains the documentation sources:
  - `docs` folder contains the documentation markdown pages
    - To write a new file: `hugo new <MD_FILE>` (example: `hugo new docs/requirements/context-map.md`)
    - For nested sections write a `_index.md` like [this one](./content/docs/requirements/_index.md)
    - [Hugo shortcuts can be useful](https://gohugo.io/content-management/shortcodes/)
    - :warning: `draft` pages are not deployed
  - `schemas` folder contains the schemas (`.cml`, `.puml`)
    - Mermaid schemas are rendered automatically inside the markdown :)
  - `res` folder contains images
