# init-post.R
# Scaffolding helper for The Burrows (BRUG's website).
# Source this file (or load via .Rprofile) to make init_post() available.
#
# init_post(slug, post_to = "blog", date = NULL, event_date = NULL,
#           event_end = NULL, event_start_time = NULL, event_end_time = NULL,
#           image = NULL, yaml_data = NULL, with_code = FALSE, ...)
#   -> {post_to}/YYYY-MM-DD-slug/index.qmd
#
# Notes on the date arguments
#   `date` is the publication date -- it controls both the front-matter
#   `date:` field and the YYYY-MM-DD prefix on the post's directory. If
#   omitted, it defaults to today.
#
#   `event_date` (post_to = "events" only) records when the meetup
#   actually happens, independent of when the announcement was posted.
#   It's written to the front matter as `event-date:`. Recall that a
#   recap post gets published *after* the event, while an announcement
#   goes up *before* it -- `date` and `event_date` are allowed to fall
#   on either side of each other, and init_post() only warns, never
#   blocks, if that ordering looks surprising.
#
#   `event_end` (requires event_date) records the last day of a
#   multi-day event. Written as `event-end:` only when supplied.
#
# Notes on the time arguments
#   `event_start_time`/`event_end_time` (post_to = "events" only,
#   event_end_time requires event_start_time) record when the meetup
#   starts and ends -- separate from event_date/event_end, which are
#   day-only. Either 12-hour ("1:30 PM") or 24-hour ("13:30") input is
#   accepted; both are normalized to "H:MM AM/PM" and written as
#   `event-start-time:`/`event-end-time:`.
#
# A note on categories, subtitle, and description
#   Unlike caow's version, this refactor does not bake in a fixed
#   taxonomy per post type. categories, subtitle, and description are
#   left as placeholders in the generated front matter for you to fill
#   in by hand -- BRUG's categories are freeform enough (meetup, brug,
#   recap, event, package, ...) that guessing at a per-section default
#   list didn't seem worth the added parameter.
#
# A note on draft status
#   This keeps Quarto's native `draft: true` rather than adopting
#   caow's custom `status:` field -- one less bespoke convention to
#   remember, and it's what the rest of The Burrows already expects.


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Parses `slug` into a directory-safe slug and a display title. Accepts
# three forms:
#   "word-slug"         -> dir: word-slug,       title: Word Slug
#   "natural language"  -> dir: natural-language, title: Natural Language
#   "`code term`"        -> dir: code-term,        title: `code term`
.resolve_slug <- function(slug) {
    is_code  <- grepl("^`.*`$", slug)
    is_words <- grepl(" ", slug) && !is_code
    
    if (is_code) {
        raw      <- gsub("^`|`$", "", slug)
        dir_slug <- gsub(" ", "-", raw)
        title    <- paste0("`", raw, "`")
        
    } else if (is_words) {
        dir_slug <- gsub(" ", "-", tolower(slug))
        title    <- tools::toTitleCase(slug)
        
    } else {
        dir_slug <- slug
        title    <- tools::toTitleCase(gsub("-", " ", slug))
    }
    
    list(dir_slug = dir_slug, title = title)
}

# Validates and normalizes a date argument to "YYYY-MM-DD".
# NULL falls back to today. Anything unparseable raises an informative error.
.resolve_date <- function(date, label = "date") {
    if (is.null(date)) {
        return(format(Sys.Date(), "%Y-%m-%d"))
    }
    
    parsed <- tryCatch(as.Date(date), error = function(e) NA)
    
    if (is.na(parsed)) {
        stop(
            "Invalid ", label, ": '", date, "'. ",
            "Expected a string R can parse as a date, e.g. '2026-03-14'.",
            call. = FALSE
        )
    }
    
    format(parsed, "%Y-%m-%d")
}

# Validates and normalizes a time argument to "H:MM AM/PM" (no leading
# zero, e.g. "1:30 PM"). Accepts either 12-hour ("1:30 PM", "1 PM") or
# 24-hour ("13:30") input. NULL passes through as NULL -- unlike
# .resolve_date(), there's no sensible "today" default for a time.
.resolve_time <- function(time, label = "time") {
    if (is.null(time)) {
        return(NULL)
    }
    
    formats <- c("%I:%M %p", "%H:%M", "%I %p")
    parsed  <- NULL
    
    for (fmt in formats) {
        attempt <- suppressWarnings(strptime(trimws(time), fmt))
        if (!is.na(attempt)) {
            parsed <- attempt
            break
        }
    }
    
    if (is.null(parsed)) {
        stop(
            "Invalid ", label, ": '", time, "'. ",
            "Expected a time R can parse, e.g. '1:30 PM' or '13:30'.",
            call. = FALSE
        )
    }
    
    sub("^0", "", format(parsed, "%I:%M %p"))
}

# Converts a "H:MM AM/PM" string (as returned by .resolve_time()) to
# minutes since midnight, for same-day ordering comparisons.
.time_to_minutes <- function(time) {
    parsed <- strptime(time, "%I:%M %p")
    parsed$hour * 60 + parsed$min
}

# Builds the author front-matter block from a YAML file containing an
# `author` key. Falls back to a blank placeholder when yaml_data is NULL.
.resolve_author <- function(yaml_data) {
    if (!is.null(yaml_data)) {
        yaml_path <- if (grepl("\\.ya?ml$", yaml_data)) yaml_data else paste0(yaml_data, ".yml")
        if (!file.exists(yaml_path)) {
            stop("yaml_data file not found: ", yaml_path, call. = FALSE)
        }
        author_data <- yaml::read_yaml(yaml_path)
        if (is.null(author_data$author)) {
            stop("yaml_data file must contain an 'author' key.", call. = FALSE)
        }
        # Pluck only `name` -- ignore all other fields in the yaml file
        authors <- lapply(author_data$author, function(a) list(name = a$name))
        yaml::as.yaml(list(author = authors))
    } else {
        'author:\n  - name: ""\n'
    }
}

# Generates a resized, center-cropped "-thumb" derivative of
# `source_path` inside `dest_dir`. Does NOT touch or copy the original.
# Returns the thumbnail's filename (not a full path) -- what belongs in
# the front-matter `image:` field.
.generate_thumbnail <- function(source_path, dest_dir, thumb_width = 1000, thumb_height = 750,
                                mode = c("cover", "contain"), bg_color = "white") {
    mode <- match.arg(mode)
    
    if (!requireNamespace("magick", quietly = TRUE)) {
        stop(
            "The magick package is required for thumbnail generation. ",
            "Install it with install.packages(\"magick\").",
            call. = FALSE
        )
    }
    if (!file.exists(source_path)) {
        stop("Image not found: ", source_path, call. = FALSE)
    }
    
    img <- magick::image_read(source_path)
    
    if (mode == "cover") {
        # Resize so the image *covers* the target box, preserving aspect
        # ratio and overflowing on one dimension; center crop trims the
        # overflow. Right for photographs -- losing a sliver off an edge
        # is harmless.
        img <- magick::image_resize(img, paste0(thumb_width, "x", thumb_height, "^"))
        img <- magick::image_crop(img, paste0(thumb_width, "x", thumb_height), gravity = "center")
    } else {
        # Resize so the image *fits within* the target box -- nothing
        # cropped -- and pad out to the exact canvas size. Right for
        # flyers and posters, where a crop-to-fill would cut off text.
        img <- magick::image_resize(img, paste0(thumb_width, "x", thumb_height))
        img <- magick::image_extent(img, paste0(thumb_width, "x", thumb_height),
                                    gravity = "center", color = bg_color)
    }
    
    base_name  <- tools::file_path_sans_ext(basename(source_path))
    ext        <- tools::file_ext(source_path)
    thumb_name <- paste0(base_name, "-thumb.", ext)
    thumb_path <- file.path(dest_dir, thumb_name)
    
    magick::image_write(img, thumb_path)
    thumb_name
}

# Assembles the YAML front matter + body as a single string.
.build_template <- function(title, author_block, date, event_date, event_end,
                            event_start_time, event_end_time, image_field, with_code) {
    image_line <- if (nzchar(image_field)) {
        paste0('image: "', image_field, '"\n')
    } else {
        ""
    }
    
    event_date_line <- if (!is.null(event_date)) {
        paste0("event-date: ", event_date, "\n")
    } else {
        ""
    }
    
    event_end_line <- if (!is.null(event_end)) {
        paste0("event-end: ", event_end, "\n")
    } else {
        ""
    }
    
    event_start_time_line <- if (!is.null(event_start_time)) {
        paste0('event-start-time: "', event_start_time, '"\n')
    } else {
        ""
    }
    
    event_end_time_line <- if (!is.null(event_end_time)) {
        paste0('event-end-time: "', event_end_time, '"\n')
    } else {
        ""
    }
    
    code_block <- if (with_code) {
        paste0(
            "format:\n",
            "  html:\n",
            "    toc: true\n",
            "    toc-depth: 3\n",
            "    toc-title: Contents\n",
            "    number-sections: false\n",
            "execute:\n",
            "  include: true\n",
            "  echo: true\n",
            "  message: false\n",
            "  error: false\n"
        )
    } else {
        ""
    }
    
    paste0(
        "---\n",
        'title: "', title, '"\n',
        'subtitle: ""\n',
        'description: "One or two sentences."\n',
        image_line,
        author_block,
        "date: ", date, "\n",
        event_date_line,
        event_end_line,
        event_start_time_line,
        event_end_time_line,
        "date-modified: last-modified\n",
        "categories: []\n",
        "draft: true\n",
        code_block,
        "---\n",
        "\n"
    )
}


# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

#' Scaffold a new post for The Burrows
#'
#' Creates {post_to}/YYYY-MM-DD-<slug>/index.qmd with front matter ready
#' to fill in. Handles blog posts, events, resources, and presentations
#' through a single function -- the distinction lives in `post_to`, not
#' in separate functions per type.
#'
#' @param slug  Post identifier. Accepts three forms:
#'   - "word-slug"         -> dir: word-slug,       title: Word Slug
#'   - "natural language"  -> dir: natural-language, title: Natural Language
#'   - "`code term`"        -> dir: code-term,        title: `code term`
#' @param post_to  One of "blog", "events", "resources", "presentations".
#'   Determines the top-level directory and, for "events", which extra
#'   arguments are meaningful.
#' @param date  Publication date, e.g. "2026-03-14". Defaults to today.
#'   Also sets the YYYY-MM-DD prefix on the post's directory.
#' @param event_date  Events only. The date the meetup actually happens,
#'   e.g. "2026-08-04" -- independent of `date`. Recorded as
#'   `event-date:` in the front matter. Ignored (with a message) if
#'   `post_to` isn't "events".
#' @param event_end  Events only. Last day of a multi-day event.
#'   Requires `event_date` to also be set. Written as `event-end:` only
#'   when supplied.
#' @param event_start_time  Events only. When the meetup starts, e.g.
#'   "1:30 PM" or "13:30" -- either 12- or 24-hour input is accepted and
#'   normalized to "H:MM AM/PM". Written as `event-start-time:`.
#' @param event_end_time  Events only. When the meetup ends. Requires
#'   `event_start_time` to also be set. Written as `event-end-time:`.
#' @param image  Optional path to a source photo that already exists
#'   somewhere on disk. Copied untouched into the post directory; a
#'   cropped/resized "-thumb" derivative is generated alongside it and
#'   used as the listing thumbnail.
#' @param yaml_data  Optional path to a .yml file containing an `author`
#'   key. If omitted, the author block is left as a blank placeholder.
#' @param with_code  If TRUE, adds toc and execute options to the front
#'   matter for posts that embed R output. Default FALSE.
#' @param thumb_width,thumb_height  Target thumbnail dimensions, in
#'   pixels. Default 1000x750 (4:3).
#' @param thumb_mode  "cover" (default) crops the image to fill the
#'   canvas. "contain" shrinks the whole image to fit within the canvas,
#'   padding the rest -- better for flyers where cropping would cut off
#'   text.
#' @param bg_color  Padding color used in "contain" mode. Default "white".
#'
#' @examples
#' init_post("Website Walkthrough", post_to = "events",
#'            event_date = "2026-08-04",
#'            event_start_time = "1:30 PM", event_end_time = "2:30 PM")
#' init_post("dplyr-joins-cheatsheet", post_to = "resources")
#' init_post("2026-attendance-summary", with_code = TRUE)
init_post <- function(slug, post_to = "blog", date = NULL, event_date = NULL,
                      event_end = NULL, event_start_time = NULL, event_end_time = NULL,
                      image = NULL, yaml_data = NULL, with_code = FALSE,
                      thumb_width = 1000, thumb_height = 750,
                      thumb_mode = "cover", bg_color = "white") {
    
    valid_sections <- c("blog", "events", "resources", "presentations")
    if (!post_to %in% valid_sections) {
        stop("post_to must be one of: ", paste(valid_sections, collapse = ", "), call. = FALSE)
    }
    
    # event_date/event_end/event_start_time/event_end_time only make
    # sense for events -- rather than erroring, warn and drop them,
    # since a stray argument shouldn't block scaffolding a blog post.
    has_event_args <- !is.null(event_date) || !is.null(event_end) ||
        !is.null(event_start_time) || !is.null(event_end_time)
    if (post_to != "events" && has_event_args) {
        message(
            "Note: event_date/event_end/event_start_time/event_end_time only ",
            "apply when post_to = \"events\". Ignoring since post_to = \"", post_to, "\"."
        )
        event_date       <- NULL
        event_end        <- NULL
        event_start_time <- NULL
        event_end_time   <- NULL
    }
    
    parsed   <- .resolve_slug(slug)
    dir_slug <- parsed$dir_slug
    title    <- parsed$title
    date     <- .resolve_date(date, "date")
    
    event_date_resolved <- NULL
    event_end_resolved  <- NULL
    
    if (!is.null(event_date)) {
        event_date_resolved <- .resolve_date(event_date, "event_date")
        if (as.Date(event_date_resolved) < as.Date(date)) {
            message(
                "Note: event_date (", event_date_resolved,
                ") is earlier than the publication date (", date,
                "). Double check this is intentional -- it would mean the ",
                "announcement went up after the event took place."
            )
        }
    }
    
    if (!is.null(event_end)) {
        if (is.null(event_date)) {
            stop(
                "event_end requires event_date to also be set -- a date ",
                "range needs both endpoints.",
                call. = FALSE
            )
        }
        event_end_resolved <- .resolve_date(event_end, "event_end")
        if (as.Date(event_end_resolved) < as.Date(event_date_resolved)) {
            message(
                "Note: event_end (", event_end_resolved,
                ") is earlier than event_date (", event_date_resolved,
                "). Double check the range is the right way round."
            )
        }
    }
    
    event_start_time_resolved <- NULL
    event_end_time_resolved   <- NULL
    
    if (!is.null(event_start_time)) {
        event_start_time_resolved <- .resolve_time(event_start_time, "event_start_time")
    }
    
    if (!is.null(event_end_time)) {
        if (is.null(event_start_time)) {
            stop(
                "event_end_time requires event_start_time to also be set -- ",
                "a time range needs both endpoints.",
                call. = FALSE
            )
        }
        event_end_time_resolved <- .resolve_time(event_end_time, "event_end_time")
        
        # Ordering only makes sense to check on a single-day event --
        # once event_end differs from event_date, "end time before
        # start time" no longer implies anything is wrong.
        if (is.null(event_end_resolved) &&
            .time_to_minutes(event_end_time_resolved) < .time_to_minutes(event_start_time_resolved)) {
            message(
                "Note: event_end_time (", event_end_time_resolved,
                ") is earlier than event_start_time (", event_start_time_resolved,
                "). Double check the range is the right way round."
            )
        }
    }
    
    if (!is.null(image) && !file.exists(image)) {
        stop("image not found: ", image, call. = FALSE)
    }
    
    dir_path  <- file.path(post_to, paste0(date, "-", dir_slug))
    post_path <- file.path(dir_path, "index.qmd")
    
    if (dir.exists(dir_path)) {
        stop("Directory already exists: ", dir_path, call. = FALSE)
    }
    
    dir.create(dir_path, recursive = TRUE)
    
    author_block <- .resolve_author(yaml_data)
    
    image_field <- ""
    if (!is.null(image)) {
        dest_original <- file.path(dir_path, basename(image))
        file.copy(image, dest_original, overwrite = FALSE)
        image_field <- .generate_thumbnail(dest_original, dir_path, thumb_width, thumb_height,
                                           mode = thumb_mode, bg_color = bg_color)
    }
    
    template <- .build_template(title, author_block, date, event_date_resolved,
                                event_end_resolved, event_start_time_resolved,
                                event_end_time_resolved, image_field, with_code)
    
    writeLines(template, post_path)
    
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
        rstudioapi::navigateToFile(post_path)
    }
    
    message("Created: ", post_path)
    if (!is.null(image)) {
        message("  + copied original: ", basename(image))
        message("  + generated thumbnail: ", image_field)
    }
    
    invisible(post_path)
}