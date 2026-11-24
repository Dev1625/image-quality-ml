source("R/quality.R")

tile_path <- function(tile, shade) {
  rows <- lapply(seq_len(nrow(tile)), function(row) {
    runs <- rle(tile[row, ])
    starts <- cumsum(runs$lengths) - runs$lengths
    keep <- runs$values == shade
    sprintf("M%d %dh%dv1h-%dz", starts[keep], row - 1, runs$lengths[keep], runs$lengths[keep])
  })
  paste(unlist(rows), collapse = "")
}

set.seed(146)
scene <- make_scene()
columns <- c(24, 226, 428)
labels <- c("Clean", "Blur", "Highlight clipping")
parts <- lapply(seq_along(classes), function(i) {
  pixels <- capture_image(scene, classes[i])
  tile <- round(pixels[seq(1, 48, by = 2), seq(1, 48, by = 2)] * 10)
  paths <- vapply(0:10, function(shade) {
    fill <- gray(shade / 10)
    sprintf('<path fill="%s" d="%s"/>', fill, tile_path(tile, shade))
  }, character(1))
  c(
    sprintf('<g transform="translate(%d 42) scale(7)">', columns[i]),
    paths,
    "</g>",
    sprintf('<text x="%d" y="236">%s</text>', columns[i], labels[i])
  )
})

dir.create("docs", showWarnings = FALSE)
writeLines(c(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 258" role="img" aria-labelledby="title desc">',
  '<title id="title">Synthetic image quality examples</title>',
  '<desc id="desc">Three captures of a generated scene under clean, blurred, and highlight-clipped conditions.</desc>',
  '<rect width="620" height="258" fill="#ecf1f1" rx="12"/>',
  '<g font-family="system-ui, sans-serif" font-size="15" fill="#172e36">',
  '<text x="24" y="26" font-weight="600">Three captures from one generated scene</text>',
  unlist(parts),
  "</g></svg>"
), "docs/synthetic-examples.svg")
