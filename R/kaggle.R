#' @title Install packages in kaggle environment
#'
#' @param include_data Logical indicating if `sitsdata` must be installed
#'
#' @importFrom utils install.packages installed.packages
#'
#' @export
install <- function(include_data = FALSE) {
    # Load required packages
    .ensure_packages(c("pak", "desc", "tibble", "dplyr", "purrr"))
    # Override CRAN repository
    pak::repo_add(CRAN = "PPM@latest")
    # Remove torch auto install
    Sys.setenv("TORCH_INSTALL" = 0)
    # Get SITS dependencies
    deps <- .get_sits_dependencies()
    # Get packages installed
    installed_pks <- tibble::as_tibble(installed.packages())
    # Get packages to install
    packages_to_install <- lapply(seq_len(nrow(deps)), function(i) {
        # Get row dependencie
        dep <- deps[i,]
        # Get package name and version
        pkg_name <- dep[["package"]]
        pkg_version <- gsub(
            pattern = ">= ",
            replacement = "",
            x = dep[["version"]]
        )
        # First row starts with R
        if (pkg_name == "R") {
            return(NULL)
        }
        # Is package installed?
        if (.has_package(pkg_name)) {
            # Is version specified?
            if (pkg_version == "*") {
                return(NULL)
            }
            # Filter package
            inst_pkg <- installed_pks[installed_pks[["Package"]] == pkg_name, ]
            # Get packages versions
            pkg_version <- package_version(pkg_version)
            inst_version <- package_version(inst_pkg[["Version"]])
            # It needs to update?
            if (pkg_version > inst_version) {
                return(tibble::tibble(
                    package = pkg_name,
                    version = as.character(pkg_version))
                )
            }
        } else {
            return(tibble::tibble(
                package = pkg_name,
                version = pkg_version
            ))
        }
    })
    # Get packages to install
    packages <- dplyr::bind_rows(packages_to_install)
    # install packages
    packages_to_install <- packages[!packages[["package"]] %in% c("torch", "terra"), ]
    # Install terra
    pak::pkg_install("terra@1.9-27")
    # Install base dependencies (not working with pak)
    install.packages(c("cols4all", "leaflegend", "maptiles", "leafem"))
    # Install dependencies
    purrr::map(packages_to_install[["package"]], pak::pak, dependencies = FALSE)
    # Install sits
    pak::pak("e-sensing/sits@dev")
    # Install sits data
    if (include_data) {
        # Check devtools
        .ensure_packages("devtools")
        # Update options
        old_options <- options(timeout = 9999)
        # Reset options
        on.exit(options(old_options), add = TRUE)
        # Install sitsdata
        devtools::install_github("e-sensing/sitsdata")
    }
    # Return!
    invisible(packages)
}

#' @title Bundle packages installed in kaggle environment
#'
#' @param output_dir Character with the output directory
#'
#' @export
bundle <- function(output_dir = ".") {
    if (Sys.which("zip") == "") {
        stop("`zip` command not found.", call. = FALSE)
    }
    # Get library with the packages installed
    lib_dir <- .libPaths()[[1]]
    # Create directory to the bundle
    output_dir <- file.path(output_dir, "sits-bundle")
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    # Create output file
    out_file <- normalizePath(
        file.path(output_dir, "sits-bundle.zip"), mustWork = FALSE
    )
    # Link library as the R version, so `patch` can find it in the datasets
    version_dir <- .r_version_dir()
    staging_dir <- tempfile()
    # Create staging directory
    dir.create(staging_dir)
    on.exit(unlink(staging_dir, recursive = TRUE), add = TRUE)
    # Create symlink to the library
    file.symlink(lib_dir, file.path(staging_dir, version_dir))
    # Set current directory to the staging directory
    current_dir <- setwd(staging_dir)
    on.exit(setwd(current_dir), add = TRUE, after = FALSE)
    # Zip packages
    status <- system2("zip", c("-r", "-q", shQuote(out_file), version_dir))
    # If `zip` failed, stop with an error
    if (status != 0) {
        stop("`zip` failed with status ", status, call. = FALSE)
    }
    # Return!
    invisible(out_file)
}

#' @title Patch kaggle environment with a bundle
#'
#' @param input_dir Character with the bundle directory. When `NULL`, the
#'                  bundle is searched in the kaggle input datasets
#' @param lib_dir Character with the library directory
#' @param exclude Character vector with packages to keep as they are
#'
#' @note Use it before loading the packages of the bundle
#'
#' @export
patch <- function(input_dir = NULL,
                  lib_dir = .libPaths()[[1]],
                  exclude = "torch") {
    # Search bundle in the kaggle input datasets
    if (is.null(input_dir)) {
        input_dir <- .find_bundle_dir()
    }
    # Get source package directories
    source_package_dirs <- list.dirs(input_dir, recursive = FALSE, full.names = TRUE)
    # Copy packages
    copied <- vapply(source_package_dirs, function(source_package_dir) {
        # Get package name
        package_name <- basename(source_package_dir)
        # If package is in the exclude list, return NA
        if (package_name %in% exclude) {
            return(NA)
        }
        # Get target package directory
        target_package_dir <- file.path(lib_dir, package_name)
        # If target package directory exists, remove it
        if (dir.exists(target_package_dir)) {
            unlink(target_package_dir, recursive = TRUE)
        }
        # Copy package to the library
        file.copy(source_package_dir, lib_dir, recursive = TRUE)
    }, logical(1))
    # Report packages not copied
    failed <- basename(source_package_dirs[!is.na(copied) & !copied])
    # If packages not copied, report them
    if (length(failed) > 0) {
        warning("Packages not copied: ", paste(failed, collapse = ", "),
                call. = FALSE)
    }
    # Get packages copied
    packages <- basename(source_package_dirs[which(copied)])
    message(length(packages), " packages copied to ", lib_dir)
    # Return!
    invisible(packages)
}
