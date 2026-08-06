
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sitskaggle <img src="man/figures/logo.svg" align="right" width="150" alt="SITS icon" />

<!-- badges: start -->

<!-- badges: end -->

Bundle SITS R package for Kaggle.

## Installation

You can install `sitskaggle` using `pak`:

``` r
pak::pak("lipeverse/sitskaggle")
```

## Example

`sitskaggle` provides only three functions: `install()`, `bundle()`, and
`patch()`. Their usage is described in the sections below.

### Creating the bundle

First, install the `sits` dependencies:

``` r
sitskaggle::install(include_data = TRUE) # Use `include_data` to include `sitsdata` in the bundle
```

Then, bundle the packages installed. This creates
`sits-bundle/sits-bundle.zip` in the directory you choose:

``` r
sitskaggle::bundle(output_dir = "/kaggle/working")
```

Now, upload the zip as a kaggle dataset. The bundle is ready, and you
only repeat these steps when you want to update the packages.

### Using the bundle

First, attach the bundle dataset to your session.

Then, patch the environment with the bundle. The bundle is searched in
the attached datasets, so no path is required:

``` r
sitskaggle::patch()
```

Now you can load `sits` and start working:

``` r
library(sits)
```

Use `patch()` before loading the packages of the bundle. Please, be
aware `torch` is not copied, as kaggle’s version must be kept.

## Contributing

Contributions are welcome. Please open an issue to discuss significant
changes, and ensure tests and linting pass before submitting a pull
request.

## License

`sitskaggle` is distributed under the GPL-v3.0 license. See
[LICENSE](./LICENSE) for the full text.
