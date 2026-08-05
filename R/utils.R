.has_package <- function(package) {
    res <- tryCatch(find.package(package = package),
                    error = function(e) NULL)
    if (is.null(res)) return(FALSE)
    return(TRUE)
}

.ensure_packages <- function(packages) {
    # Packages are suggested, as sitskaggle is installed without dependencies
    missing <- packages[!vapply(packages, .has_package, logical(1))]
    # If packages are missing, we install them
    if (length(missing) > 0) {
        install.packages(missing)
    }
    # Return!
    invisible(missing)
}

.get_sits_dependencies <- function() {
    url <- "https://raw.githubusercontent.com/e-sensing/sits/refs/heads/dev/DESCRIPTION"
    description <- desc::desc(text = readLines(url))
    description$get_deps()
}

.r_version_dir <- function() {
    # We assume library is aligned with the version of kaggle
    paste(R.version[["major"]], sub("\\..*$", "", R.version[["minor"]]), sep = ".")
}

.is_library_dir <- function(dir) {
    # List possible packages
    packages <- list.dirs(dir, recursive = FALSE, full.names = TRUE)
    # A library directory, must contain at least one description file!
    any(file.exists(file.path(packages, "DESCRIPTION")))
}

.find_bundle_dir <- function(root = "/kaggle/input", max_depth = 5) {
    # If not in kaggle, skip it
    if (!dir.exists(root)) {
        stop("Directory not found: ", root, call. = FALSE)
    }
    # Get version directory
    version <- .r_version_dir()
    # Define candidates directory
    candidates <- character()
    # Current level is the root
    level <- root
    # Search level by level
    for (depth in seq_len(max_depth)) {
        # If there is no extra level, exit
        if (length(level) == 0) {
            break
        }
        # Get directories that match the version and are libraries
        matched <- basename(level) == version & vapply(level, .is_library_dir, logical(1))
        # Add matched directories to the candidates
        candidates <- c(candidates, level[matched])
        # Matched directories are libraries, so there is nothing below them
        level <- list.dirs(level[!matched], recursive = FALSE, full.names = TRUE)
    }
    # If no candidates were found, stop with an error
    if (length(candidates) == 0) {
        stop("No bundle for R ", version, " found in ", root,
             ". Use `input_dir` to define it.", call. = FALSE)
    }
    # If multiple candidates were found, stop with an error
    if (length(candidates) > 1) {
        stop("Multiple bundles found, use `input_dir` to define one: ",
             paste(candidates, collapse = ", "), call. = FALSE)
    }
    # Return!
    candidates
}
