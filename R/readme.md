# init_post()

A small R helper for scaffolding new content on [The Burrows](https://github.com/erwinlares/the-burrows), BRUG's Quarto site. It creates a new post directory with a pre-filled `index.qmd`, so you don't have to hand-write YAML frontmatter every time.

## Usage

```r
init_post(
  slug,
  post_to = "blog",
  date = NULL,
  event_date = NULL,
  event_end = NULL,
  event_start_time = NULL,
  event_end_time = NULL,
  image = NULL,
  yaml_data = NULL,
  with_code = FALSE,
  thumb_width = 1000,
  thumb_height = 750,
  thumb_mode = "cover",
  bg_color = "white"
)
```

### Core arguments

| Argument | Required | Default | Description |
|---|---|---|---|
| `slug` | Yes | — | The post's working title. Accepts plain words (`"targets pipelines"`), a hyphenated slug (`"targets-pipelines"`), or a code span (`` "`renv::snapshot()`" ``) — the function detects the style and titles the post accordingly. |
| `post_to` | No | `"blog"` | Which section of the site the post belongs to. Must be one of `"blog"`, `"events"`, `"resources"`, `"presentations"` — these map directly to the folders defined in `_quarto.yml`. |
| `date` | No | today | Publication date, e.g. `"2026-03-14"`. Controls both the front-matter `date:` field and the `YYYY-MM-DD` prefix on the post's directory. Worth overriding by hand for a recap written a day or two after the event it describes. |
| `yaml_data` | No | `NULL` (blank placeholder) | Path to a `.yml` file with an `author:` key — see [Author](#author) below. |

### Event arguments (`post_to = "events"` only)

These only apply to event posts. If you pass any of them while `post_to` is something else, `init_post()` won't error — it just drops them with a message, since a stray argument shouldn't block scaffolding a blog post.

| Argument | Required | Default | Description |
|---|---|---|---|
| `event_date` | No | `NULL` | The date the meetup actually happens, independent of `date`. Written as `event-date:`. Recall that a recap gets published *after* the event while an announcement goes up *before* it — `date` and `event_date` are allowed to fall on either side of each other; `init_post()` only warns, never blocks, if the ordering looks surprising. |
| `event_end` | No | `NULL` | Last day of a multi-day event. Requires `event_date` to also be set. Written as `event-end:` only when supplied. |
| `event_start_time` | No | `NULL` | When the meetup starts. Accepts either 12-hour (`"1:30 PM"`) or 24-hour (`"13:30"`) input; both are normalized to `"H:MM AM/PM"` and written as `event-start-time:`. |
| `event_end_time` | No | `NULL` | When the meetup ends. Requires `event_start_time` to also be set. Written as `event-end-time:`. |

### Image arguments

| Argument | Required | Default | Description |
|---|---|---|---|
| `image` | No | `NULL` | Path to a source photo that already exists on disk. Copied untouched into the post directory; a cropped/resized `-thumb` derivative is generated alongside it and used as the listing thumbnail. Requires the `magick` package. |
| `thumb_width`, `thumb_height` | No | `1000`, `750` | Target thumbnail dimensions, in pixels (4:3 by default). |
| `thumb_mode` | No | `"cover"` | `"cover"` crops the image to fill the thumbnail canvas — right for photographs, where losing a sliver off an edge is harmless. `"contain"` shrinks the whole image to fit within the canvas and pads the rest — right for flyers or posters, where a crop-to-fill would cut off text. |
| `bg_color` | No | `"white"` | Padding color used in `"contain"` mode. |

### `with_code`

If `TRUE`, adds a `toc` and `execute` block to the front matter, for posts that embed live R output. Default `FALSE`.

## Author

Author names don't get passed in directly. Instead, point `yaml_data` at a `.yml` file with an `author:` key:

```yaml
author:
  - name: "Erwin Lares"
  - name: "Jayden Merrick"
```

`init_post()` reads the file, pulls out just the `name` field for each entry (ignoring anything else in the file), and writes the corresponding `author:` block into the front matter. If `yaml_data` is omitted, the author block is left as a blank placeholder for you to fill in by hand.

### What it does

1. Derives a title and a URL-safe slug from your input.
2. Builds a directory-per-post path: `{post_to}/{YYYY-MM-DD}-{slug}/index.qmd`.
3. Refuses to run if that directory already exists, so you can't accidentally clobber a post.
4. If `image` is supplied, copies the original into the post directory and generates a resized, cropped `-thumb` derivative for the listing.
5. Writes an `index.qmd` with pre-filled frontmatter (title, description placeholder, author block, date, event fields where relevant, `draft: true`).
6. Opens the new file in RStudio, if you're running this from within RStudio.

### Example

A blog post:

```r
init_post(
  "BRUG Meeting 1 Soft Opening",
  post_to = "blog",
  yaml_data = "authors.yml"
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
categories: []
draft: true
---
```

An event announcement, with a flyer image and start/end times:

```r
init_post(
  "Website Walkthrough",
  post_to = "events",
  event_date = "2026-08-04",
  event_start_time = "1:30 PM",
  event_end_time = "2:30 PM",
  image = "flyer.png"
)
```

## Categories

`categories` isn't a function argument — the template always writes `categories: []`, and you fill it in by hand once the file is open. This is intentional: The Burrows doesn't enforce a fixed category list, and BRUG's categories are freeform enough (meetup, brug, recap, event, package, ...) that guessing at a per-section default list didn't seem worth the added parameter.

A non-exhaustive set of tags already in use or expected across the site:

`meetup` · `recap` · `reproducibility` · `tools` · `data science` · `r` · `brug` · `research workflow` · `project organization` · `renv` · `git` · `chtc` · `portable code` · `accessibility` · `coding` · `productivity`

Feel free to introduce a new tag if none of these fit — just try to reuse an existing one if it's close, so the tag list doesn't fragment.

## Draft status

New posts are created with `draft: true`, which is Quarto's native mechanism — draft posts are excluded from listings and the site's navigation but can still be previewed and built locally. Flip it to `false` (or remove the line) when the post is ready to go live.

## Requirements

- `tools` (base R, for `toTitleCase()`)
- `rstudioapi`, optional — only used to auto-open the new file if you're working in RStudio. Guarded with `rstudioapi::isAvailable()`, so it won't error if you're running this from a plain R console or a script.
- `magick`, optional — only required if you pass `image`, for generating the thumbnail.
- `yaml`, optional — only required if you pass `yaml_data`, for reading the author file.

## Not included

This is intentionally scaffolding-only. It does not:

- Fill in a description, abstract, subtitle, or category list — that's on you, by hand, once the file is open.
- Validate categories against a controlled vocabulary.
- Cross-post to any other site. Everything this function creates is scoped to The Burrows.

## Getting started

Run `get_started()` for a quick reference printed straight to the console — handy if you don't want to scroll back through this file every time.