init_post <- function(slug, post_to = "blog", categories = NULL, author = NULL) {
    
    valid_sections <- c("blog", "events", "resources", "presentations")
    if (!post_to %in% valid_sections) {
        stop("post_to must be one of: ", paste(valid_sections, collapse = ", "), call. = FALSE)
    }
    
    # Detect input style and derive directory slug + YAML title accordingly
    is_code <- grepl("^`.*`$", slug)
    is_words <- grepl(" ", slug) && !is_code
    
    if (is_code) {
        raw <- gsub("^`|`$", "", slug)
        dir_slug <- gsub(" ", "-", raw)
        title <- paste0("`", raw, "`")
    } else if (is_words) {
        dir_slug <- gsub(" ", "-", tolower(slug))
        title <- tools::toTitleCase(slug)
    } else {
        dir_slug <- slug
        title <- tools::toTitleCase(gsub("-", " ", slug))
    }
    
    # Build paths
    date <- format(Sys.Date(), "%Y-%m-%d")
    dir_path <- file.path(post_to, paste0(date, "-", dir_slug))
    post_path <- file.path(dir_path, "index.qmd")
    
    if (dir.exists(dir_path)) {
        stop("Directory already exists: ", dir_path, call. = FALSE)
    }
    
    # Author block — one or more names, or a blank placeholder if none given
    if (!is.null(author)) {
        author_lines <- paste0('  - name: "', author, '"\n', collapse = "")
    } else {
        author_lines <- '  - name: ""\n'
    }
    author_block <- paste0("author:\n", author_lines)
    
    # Categories block — passed in at call time, no fixed taxonomy baked in
    if (!is.null(categories)) {
        cat_lines <- paste0("  - ", categories, "\n", collapse = "")
        categories_block <- paste0("categories:\n", cat_lines)
    } else {
        categories_block <- "categories: []\n"
    }
    
    dir.create(dir_path, recursive = TRUE)
    
    template <- paste0(
        "---\n",
        'title: "', title, '"\n',
        'subtitle: ""\n',
        'description: "One or two sentences."\n',
        author_block,
        "date: ", date, "\n",
        "date-modified: last-modified\n",
        categories_block,
        "draft: true\n",
        "---\n",
        "\n"
    )
    
    writeLines(template, post_path)
    
    if (rstudioapi::isAvailable()) {
        rstudioapi::navigateToFile(post_path)
    }
    
    message("Created: ", post_path)
    invisible(post_path)
}