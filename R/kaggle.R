#' @title Install packages in kaggle environment
#'
#' @export
install <- function() {
    .has_package <- function(package) {
        res <- tryCatch(find.package(package = package),
                        error = function(e) NULL)
        if (is.null(res)) return(FALSE)
        return(TRUE)
    }

    url <- "https://raw.githubusercontent.com/e-sensing/sits/refs/heads/dev/DESCRIPTION"
    description <- desc::desc(text = readLines(url))
    deps <- description$get_deps()

    installed_pks <- installed.packages()
    installed_pks <- tibble::as_tibble(installed_pks)

    packages_to_install <- lapply(seq_len(nrow(deps)), function(i) {
        dep <- deps[i,]
        pkg_name <- dep[["package"]]
        if (pkg_name == "R") return(NULL)
        pkg_version <- dep[["version"]]
        pkg_version <- gsub(pattern = ">= ", replacement = "", x = pkg_version)

        if (.has_package(pkg_name)) {
            if (pkg_version == "*") {
                return(NULL)
            }
            pkg_version <- package_version(pkg_version)
            inst_pkg <- installed_pks[installed_pks[["Package"]] == pkg_name, ]
            inst_version <- package_version(inst_pkg[["Version"]])

            if (pkg_version > inst_version) {
                return(
                    tibble::tibble(package = pkg_name,
                                   version = as.character(pkg_version))
                )
            }
        } else {
            return(
                tibble::tibble(package = pkg_name, version = pkg_version)
            )
        }
    })
    # Get packages to install
    packages <- dplyr::bind_rows(packages_to_install)
    # Remove torch
    packages_to_install <- packages[packages[["package"]] != "torch", ]
    # install packages
    install.packages(packages_to_install[["package"]])
    # Install torch
    Sys.setenv("CUDA" = "12.8")
    options(timeout = 600)
    # Install cuda package
    install.packages(
        "cuda12.8",
        repos = c("https://mlverse.r-universe.dev",
                  "https://cloud.r-project.org")
    )
    # Install torch package
    install.packages("torch")
    torch::install_torch()
    # Return!
    return(packages)
}

#' @title Bundle into kaggle environment
#'
#' @export
bundle <- function() {
    system("cp -u -R ../input/sits-bundle/sits-bundle/* /usr/local/lib/R/site-library/")
}
