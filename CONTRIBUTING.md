---
title: "Contributing to BRUG"
---

# **Contributing to BRUG**

Welcome, and thank you for contributing to the Badger R Users Group website. This site is built and maintained by the BRUG community — which means it is built and maintained by you. Whether you are sharing a workflow that saved your afternoon, posting slides from a recent meetup, or pointing the group toward a package worth knowing, your contribution makes BRUG more useful for everyone.

## **What can I contribute?**

We welcome four types of contributions:

Blog posts are the most open-ended format. A post might be a short reflection on a problem you solved, a walkthrough of a tool or workflow, a recap of something you learned at a conference, or an honest account of something that didn't work and why. Posts live in `blog/posts/` and should include a reproducible example where relevant.

Resources are curated additions to one of the topic pages (visualization, wrangling, reproducibility, HPC, and others as they grow). A resource contribution might be a link with a short annotation, a code snippet, or a brief comparison of approaches. Resources live in `resources/` under the appropriate topic file.

Presentations are slides or supporting materials from a BRUG meetup or related event. Presentations live in `presentations/` in a dated subfolder (`YYYY-MM-DD-title/`). A short abstract or description in the `index.qmd` is appreciated but not required.

Site improvements are contributions to the infrastructure of the site itself — fixing a broken link, improving navigation, updating the about page, or proposing a new topic section. These are always welcome.

## **How do I contribute?**

1. Fork the repository and create a branch for your contribution.  
2. Add your content following the structure described above and the format notes below.  
3. Open a pull request using the provided template. Describe what you are contributing and what type of contribution it is.  
4. A BRUG officer will review your PR and either merge it or follow up with light feedback. We aim to review PRs within two weeks.

If you are new to pull requests, that is completely fine — this is a good place to practice. Feel free to open a draft PR early and ask questions in the comments.

## **Format notes**

These are suggestions, not hard rules. When in doubt, submit what you have and we will work it out together.

Blog posts should include a YAML header with at least a title, author, and date. Something like:

```yaml
---
title: "A title that tells me what I will learn"
author: "Your Name"
date: "YYYY-MM-DD"
categories: [reproducibility, wrangling, visualization, HPC, other]
---
```

A post should be self-contained where possible. If your post depends on data or external files, include them in the post's subfolder under `data/`. If your post includes code, aim for examples that a reader can run on their own machine without heroics.

Resources should include a brief annotation — one or two sentences explaining why this resource is worth the reader's time. A link alone is less useful than a link with context.

Presentations should include an `index.qmd` with at minimum a title, presenter name, and date. Slides can be in any format (Quarto, PDF, HTML), though Quarto is preferred for consistency.

## **A note on tone**

BRUG is a place for researchers at all levels of R experience. Contributions should be written with that range in mind — accessible to someone earlier in their R journey without being condescending to someone who has been writing packages for a decade. When in doubt, err on the side of more context rather than less.

## **Questions?**

Open an issue or reach out to the BRUG officers directly. We are glad you are here.  
