## What this PR adds

<!-- One sentence describing the resource. Example: "Adds curriculr, an R package for building data-driven CVs." -->

---

## Checklist

Before opening this PR, please confirm the following:

- [ ] I created a new file at `resources/<resource-name>/index.qmd`
- [ ] The YAML front matter includes all required fields (see below)
- [ ] The body is at least one short paragraph describing the resource
- [ ] I have not modified any files outside the `resources/` folder

---

## Required front matter

Your `index.qmd` should open with a YAML block that looks like this:

```yaml
---
title: "resource name"
date: YYYY-MM-DD
description: >
  A one or two sentence description of what this resource does and who
  it is for. This text appears in the listing, so make it informative.
categories: [category1, category2]
---
```

**A few notes on each field:**

`title` — the name of the resource as you want it displayed on the site. Use the canonical name (e.g. `"ggplot2"`, not `"the ggplot2 package"`).

`date` — the date you are submitting, in `YYYY-MM-DD` format.

`description` — shown in the resource listing. One or two sentences is enough; aim for what the resource *does*, not what it *is*. Avoid starting with the title repeated back (`"curriculr is a package that..."` → just say what it does).

`categories` — a list of lowercase tags. Pick from existing categories where possible to keep the listing consistent. Common ones include: `productivity`, `reproducibility`, `visualization`, `data-wrangling`, `reporting`, `teaching`, `statistics`.

---

## Body

After the YAML block, write at least one paragraph. Link to the resource using Markdown:

```markdown
[Resource name](https://link-to-resource.com) does X by doing Y.
```

A good body paragraph explains the main idea in plain language — what problem it solves, what makes it worth knowing about. Two to four sentences is a reasonable target. You do not need headers or bullet points.

---

## Example

Here is a complete `index.qmd` for reference:

```yaml
---
title: "curriculr"
date: 2026-06-01
description: >
  An R package for producing data-driven CVs and resumes. You maintain your
  content in an Excel workbook; curriculr reads it, converts it to Typst
  layout blocks, and renders a polished PDF via Quarto. No LaTeX required.
categories: [productivity, reproducibility, cv]
---
```

```markdown
[curriculr](https://erwinlares.github.io/curriculr/index.html) separates
content from layout: your CV data lives in the spreadsheet, rendering
configuration lives in Quarto, and transformation logic lives in small,
reusable R functions.
```

---

## Questions?

If you are unsure about categories, file location, or anything else, open the PR anyway and leave a note here. We can sort it out in review.
