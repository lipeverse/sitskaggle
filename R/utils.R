.has_package <- function(package) {
    res <- tryCatch(find.package(package = package),
                    error = function(e) NULL)
    if (is.null(res)) return(FALSE)
    return(TRUE)
}

.get_sits_dependencies <- function() {
    url <- "https://raw.githubusercontent.com/e-sensing/sits/refs/heads/dev/DESCRIPTION"
    description <- desc::desc(text = readLines(url))
    description$get_deps()
}
