#' @title Install packages in kaggle environment
#'
#' @param output_dir Character with the output directory
#'
#' @export
install <- function(output_dir) {
    # Override CRAN
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
                version = pkg_version)
            )
        }
    })
    # Get packages to install
    packages <- dplyr::bind_rows(packages_to_install)
    # install packages
    packages_to_install <- packages[!packages[["package"]] %in% c("torch", "terra"), ]
    # Install terra
    pak::pkg_install("terra@1.9-27")
    # Remove torch
    pak::pak(packages_to_install[["package"]], dependencies = FALSE, upgrade = TRUE)
    # Install sits
    pak::pak("e-sensing/sits@dev")
    # Create directory to the bundle
    output_dir <- paste0(output_dir, "/sits-bundle")
    dir.create(output_dir)
    # Create output file
    out_file <- paste0(output_dir, "/sits-bundle.zip")
    # Zip packages
    system(paste("zip -r", out_file, "/usr/local/lib/R/site-library/"))
    # Return!
    return(packages)
}

#' @title Bundle into kaggle environment
#'
#' @export
bundle <- function() {
    system("cp -u -R ../input/sits-bundle/sits-bundle/* /usr/local/lib/R/site-library/")
}
