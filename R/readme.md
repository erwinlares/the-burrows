# init_post()

A small R helper for scaffolding new content on [The Burrows](https://github.com/erwinlares/the-burrows), BRUG's Quarto site. It creates a new post directory with a pre-filled `index.qmd`, so you don't have to hand-write YAML frontmatter every time.

## Usage

```r
init_post(slug, post_to = "blog", categories = NULL, author = NULL)
```

### Arguments

| Argument | Required | Default | Description |
|---|---|---|---|
| `slug` | Yes | — | The post's working title. Accepts plain words (`"targets pipelines"`), a hyphenated slug (`"targets-pipelines"`), or a code span (`` "`renv::snapshot()`" ``) — the function detects the style and titles the post accordingly. |
| `post_to` | No | `"blog"` | Which section of the site the post belongs to. Must be one of `"blog"`, `"events"`, `"resources"`, `"presentations"` — these map directly to the folders defined in `_quarto.yml`. |
| `categories` | No | `NULL` (empty) | A character vector of tags for the post, e.g. `c("r", "reproducibility")`. Not validated against a fixed list — see [Categories](#categories) below. |
| `author` | No | `NULL` (blank placeholder) | A character vector of one or more contributor names, e.g. `c("Erwin Lares", "Jayden Merrick")`. Each name gets its own `author:` entry. |

### What it does

1. Derives a title and a URL-safe slug from your input.
2. Builds a directory-per-post path: `{post_to}/{YYYY-MM-DD}-{slug}/index.qmd`.
3. Refuses to run if that directory already exists, so you can't accidentally clobber a post.
4. Writes an `index.qmd` with pre-filled frontmatter (title, description placeholder, author block, date, categories, `draft: true`).
5. Opens the new file in RStudio, if you're running this from within RStudio.

### Example

```r
init_post(
  "BRUG Meeting 1 Soft Opening",
  post_to = "blog",
  categories = c("meetup", "brug"),
  author = "Erwin Lares"
)
```

Produces `blog/2026-07-09-brug-meeting-1-soft-opening/index.qmd`:

```yaml
---
title: "BRUG Meeting 1 Soft Opening"
subtitle: ""
description: "One or two sentences."
author:
  - name: "Erwin Lares"
date: 2026-07-09
date-modified: last-modified
categories:
  - meetup
  - brug
draft: true
---
```

Note the date reflects the day you run the function, not necessarily the date of the event the post is about — edit `date:` by hand if they differ (as with a meeting recap written a day or two after the fact).

## Categories

The Burrows doesn't enforce a fixed category list — `categories` is free text, passed in at call time rather than baked into the function. A non-exhaustive set of tags already in use or expected across the site:

`meetup` · `recap` · `reproducibility` · `tools` · `data science` · `r` · `brug` · `research workflow` · `project organization` · `renv` · `git` · `chtc` · `portable code` · `accessibility` · `coding` · `productivity`

Feel free to introduce a new tag if none of these fit — just try to reuse an existing one if it's close, so the tag list doesn't fragment.

## Draft status

New posts are created with `draft: true`, which is Quarto's native mechanism — draft posts are excluded from listings and the site's navigation but can still be previewed and built locally. Flip it to `false` (or remove the line) when the post is ready to go live.

## Requirements

- `tools` (base R, for `toTitleCase()`)
- `rstudioapi`, optional — only used to auto-open the new file if you're working in RStudio. The function checks `rstudioapi::isAvailable()` first, so it won't error if you're running this from a plain R console or a script.

## Not included

This is intentionally scaffolding-only. It does not:

- Fill in a description, abstract, or body content — that's on you.
- Validate categories against a controlled vocabulary.
- Cross-post to any other site. Everything this function creates is scoped to The Burrows.