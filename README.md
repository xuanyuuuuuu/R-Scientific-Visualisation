# R Scientific Visualisation

A collection of reusable R scripts for scientific figures. Each visualisation
has its own folder containing the script, example input, and rendered example.

## World sample distribution

Create a publication-ready world map from country-level sample counts. Countries
are matched using ISO 3166-1 alpha-3 codes, and positive counts are displayed on
a log10 colour scale.

### Files

- [`world_sample_distribution.R`](maps/world-sample-distribution/world_sample_distribution.R): plotting script
- [`example_data.csv`](maps/world-sample-distribution/example_data.csv): example input spanning the Americas, Europe, Africa, Asia, and Oceania
- [`example_map.png`](maps/world-sample-distribution/example_map.png): rendered example

### Input

The input must be a CSV file containing:

| Column | Description |
| --- | --- |
| `iso3` | ISO 3166-1 alpha-3 country code, such as `USA` or `AUS` |
| `sample_count` | Non-negative numeric sample count |

Extra columns are ignored. Repeated ISO3 codes are summed. A country with a zero
count is displayed using the no-data colour.

### Setup

Install R 4.1 or newer, then install the dependencies:

```r
install.packages(c(
  "ggplot2", "sf", "rnaturalearth", "readr",
  "dplyr", "scales", "units", "svglite"
))
```

### Run the example

From the repository root:

```sh
Rscript maps/world-sample-distribution/world_sample_distribution.R \
  --input maps/world-sample-distribution/example_data.csv \
  --out maps/world-sample-distribution/example_map.png
```

Windows PowerShell users can run the same command on one line:

```powershell
Rscript maps/world-sample-distribution/world_sample_distribution.R --input maps/world-sample-distribution/example_data.csv --out maps/world-sample-distribution/example_map.png
```

The output directory is created automatically. SVG and PDF are also supported
by changing the output filename extension.

## Repository layout

```text
R-Scientific-Visualisation/
|-- README.md
|-- LICENSE
`-- maps/
    `-- world-sample-distribution/
        |-- world_sample_distribution.R
        |-- example_data.csv
        `-- example_map.png
```

## License

MIT. See [`LICENSE`](LICENSE).
