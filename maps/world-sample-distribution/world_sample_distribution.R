#!/usr/bin/env Rscript

# Create a country-level sample map from ISO3 codes and sample counts.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(key, default = NULL) {
  positions <- which(args == key)
  if (length(positions) == 0L || positions[1] == length(args)) {
    return(default)
  }
  args[positions[1] + 1L]
}

infile <- get_arg("--input")
outfile <- get_arg("--out")

if (is.null(infile) || is.null(outfile)) {
  stop(
    paste(
      "Usage: Rscript maps/world-sample-distribution/world_sample_distribution.R",
      "--input example_data.csv --out example_map.png"
    ),
    call. = FALSE
  )
}

required_packages <- c(
  "ggplot2", "sf", "rnaturalearth", "readr",
  "dplyr", "scales", "units"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Install missing packages: ", paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
  library(readr)
  library(dplyr)
  library(scales)
  library(units)
})

if (!file.exists(infile)) {
  stop("Input file does not exist: ", infile, call. = FALSE)
}

raw_samples <- read_csv(infile, show_col_types = FALSE)
required_columns <- c("iso3", "sample_count")
missing_columns <- setdiff(required_columns, names(raw_samples))
if (length(missing_columns) > 0L) {
  stop(
    "Input is missing required column(s): ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

samples <- raw_samples |>
  transmute(
    iso3 = toupper(trimws(as.character(iso3))),
    sample_count = suppressWarnings(as.numeric(sample_count))
  )

invalid_iso3 <- is.na(samples$iso3) | !grepl("^[A-Z]{3}$", samples$iso3)
invalid_counts <- is.na(samples$sample_count) | !is.finite(samples$sample_count) |
  samples$sample_count < 0

if (any(invalid_iso3)) {
  stop("Every iso3 value must be a three-letter country code.", call. = FALSE)
}
if (any(invalid_counts)) {
  stop("Every sample_count must be a finite, non-negative number.", call. = FALSE)
}

samples <- samples |>
  group_by(iso3) |>
  summarise(Samples = sum(sample_count), .groups = "drop")

sf::sf_use_s2(FALSE)

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") |>
  st_make_valid() |>
  mutate(map_iso3 = if_else(iso_a3 == "-99", adm0_a3, iso_a3)) |>
  st_transform("+proj=eqearth")

unmatched_iso3 <- setdiff(samples$iso3, unique(world$map_iso3))
if (length(unmatched_iso3) > 0L) {
  warning(
    "ISO3 code(s) not found in the map data: ",
    paste(unmatched_iso3, collapse = ", "),
    call. = FALSE
  )
}

graticules <- st_graticule(
  lon = seq(-180, 180, by = 20),
  lat = seq(-80, 80, by = 20)
) |>
  st_transform("+proj=eqearth")

world_merged <- world |>
  left_join(samples, by = c("map_iso3" = "iso3")) |>
  mutate(Samples_plot = if_else(!is.na(Samples) & Samples > 0, Samples, NA_real_))

plot <- ggplot() +
  geom_sf(data = graticules, color = "grey85", linewidth = 0.2) +
  geom_sf(
    data = world_merged,
    aes(fill = Samples_plot),
    color = "white",
    linewidth = 0.2
  ) +
  scale_fill_gradient(
    trans = "log10",
    low = "#e6f2ff",
    high = "#084594",
    breaks = c(1, 10, 100, 1000, 10000),
    labels = label_number(accuracy = 1, big.mark = ","),
    na.value = "#f0f0f0",
    name = "Samples"
  ) +
  theme_void(base_family = "sans") +
  guides(
    fill = guide_colorbar(
      title = "Samples",
      barheight = unit(22, "mm"),
      barwidth = unit(4, "mm"),
      ticks.colour = "grey50"
    )
  ) +
  theme(
    legend.position = c(0.10, 0.18),
    legend.justification = c(0, 0),
    legend.background = element_rect(fill = "transparent", color = NA),
    legend.title = element_text(size = 9),
    legend.text = element_text(size = 8),
    plot.margin = margin(5, 5, 5, 5)
  )

dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)

if (grepl("\\.svg$", outfile, ignore.case = TRUE)) {
  if (!requireNamespace("svglite", quietly = TRUE)) {
    stop("Install package 'svglite' to create SVG output.", call. = FALSE)
  }
  ggsave(
    filename = outfile,
    plot = plot,
    width = 180,
    height = 120,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
} else {
  ggsave(
    filename = outfile,
    plot = plot,
    width = 180,
    height = 120,
    units = "mm",
    bg = "white"
  )
}

message("Saved map to: ", normalizePath(outfile, winslash = "/", mustWork = FALSE))
