classes <- c("clean", "blur", "clipping")
base_features <- c("mean_light", "contrast", "edge_strength", "bright_share")
features <- c(base_features, "edge_peak_ratio")

make_scene <- function(size = 48) {
  axis <- seq(-1, 1, length.out = size)
  x <- matrix(rep(axis, each = size), nrow = size)
  y <- t(x)
  image <- runif(1, 0.25, 0.65) + runif(1, -0.16, 0.16) * x
  image <- image + runif(1, -0.14, 0.14) * y

  # Vary shapes, positions and contrast from scene to scene.
  for (i in seq_len(5)) {
    cx <- runif(1, -0.65, 0.65)
    cy <- runif(1, -0.65, 0.65)
    width <- runif(1, 0.08, 0.35)
    height <- runif(1, 0.05, 0.30)
    shape <- abs(x - cx) < width & abs(y - cy) < height
    image <- image + shape * runif(1, -0.31, 0.37)
  }

  radius <- runif(1, 0.17, 0.43)
  dist <- (x - runif(1, -0.55, 0.55))^2 + (y - runif(1, -0.55, 0.55))^2
  image <- image - (dist < radius^2) * runif(1, 0.15, 0.36)
  image + runif(1, 0.02, 0.09) * sin(runif(1, 8, 22) * (x + 0.5 * y))
}

box_blur <- function(image) {
  rows <- seq_len(nrow(image))
  cols <- seq_len(ncol(image))
  result <- image * 0
  for (dy in -1:1) {
    for (dx in -1:1) {
      r <- pmin(nrow(image), pmax(1, rows + dy))
      c <- pmin(ncol(image), pmax(1, cols + dx))
      result <- result + image[r, c]
    }
  }
  result / 9
}

capture_image <- function(scene, label) {
  image <- scene * runif(1, 0.86, 1.15) + runif(1, -0.10, 0.12)
  if (label == "blur") {
    amount <- runif(1, 0.56, 1)
    image <- (1 - amount) * image + amount * box_blur(box_blur(image))
  }
  if (label == "clipping") {
    image <- 1.3 * image + runif(1, 0.16, 0.43)
  }

  noise <- rnorm(length(image), sd = runif(1, 0.008, 0.035))
  # Clip at the sensor bounds while retaining matrix dimensions.
  pmin(pmax(image + noise, 0), 1)
}

measure_image <- function(image) {
  rows <- nrow(image)
  cols <- ncol(image)
  dx <- image[, 2:cols] - image[, 1:(cols - 1)]
  dy <- image[2:rows, ] - image[1:(rows - 1), ]
  edges <- abs(c(dx, dy))
  edge_mean <- mean(edges)
  c(
    mean_light = mean(image),
    contrast = sd(as.vector(image)),
    edge_strength = edge_mean,
    bright_share = mean(image >= 0.98),
    edge_peak_ratio = quantile(edges, 0.98, names = FALSE) / max(edge_mean, 1e-8)
  )
}

make_data <- function(scene_count = 120, repeats = 3, seed = 24) {
  set.seed(seed)
  scenes <- lapply(seq_len(scene_count), function(i) {
    scene <- make_scene()
    labels <- rep(classes, each = repeats)
    values <- t(vapply(labels, function(label) {
      measure_image(capture_image(scene, label))
    }, numeric(length(features))))
    data.frame(scene = i, label = factor(labels, levels = classes), values,
               row.names = NULL)
  })
  do.call(rbind, scenes)
}

split_scenes <- function(data, test_share = 0.25, seed = 81) {
  groups <- unique(data$scene)
  stopifnot(length(groups) >= 2, test_share > 0, test_share < 1)
  count <- min(length(groups) - 1, max(1, round(length(groups) * test_share)))
  set.seed(seed)
  test_groups <- sample(groups, count)
  in_test <- data$scene %in% test_groups
  list(train = data[!in_test, ], test = data[in_test, ])
}

fit_tree <- function(data, predictors = features) {
  rpart::rpart(
    reformulate(predictors, response = "label"), data = data, method = "class",
    control = rpart::rpart.control(maxdepth = 4, minsplit = 16, cp = 0.005, xval = 0)
  )
}

scores <- function(actual, predicted) {
  counts <- table(
    actual = factor(actual, levels = classes),
    predicted = factor(predicted, levels = classes)
  )
  stopifnot(all(rowSums(counts) > 0))
  recall <- diag(counts) / rowSums(counts)
  list(confusion = counts, recall = recall, balanced_accuracy = mean(recall))
}
