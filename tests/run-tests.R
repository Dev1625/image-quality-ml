source("R/quality.R")

grid <- matrix(rep(c(0.2, 0.8), 24), nrow = 6)
stopifnot(measure_image(box_blur(grid))["edge_strength"] < measure_image(grid)["edge_strength"])

set.seed(24)
scene <- make_scene()
for (label in classes) {
  image <- capture_image(scene, label)
  stopifnot(identical(dim(image), c(48L, 48L)), all(image >= 0 & image <= 1))
}

data <- make_data(scene_count = 36, repeats = 2)
stopifnot(identical(data, make_data(scene_count = 36, repeats = 2)))
stopifnot(nrow(data) == 216, all(is.finite(as.matrix(data[features]))))

split <- split_scenes(data)
stopifnot(length(intersect(split$train$scene, split$test$scene)) == 0)
stopifnot(nrow(split$train) + nrow(split$test) == nrow(data))
stopifnot(length(unique(split$test$scene)) == 9)
dev <- split_scenes(split$train, seed = 90)
stopifnot(length(intersect(dev$train$scene, dev$test$scene)) == 0)
stopifnot(length(intersect(dev$test$scene, split$test$scene)) == 0)

tree <- fit_tree(split$train)
prediction <- predict(tree, split$test, type = "class")
result <- scores(split$test$label, prediction)
stopifnot(sum(result$confusion) == nrow(split$test))
stopifnot(isTRUE(all.equal(scores(classes, classes)$balanced_accuracy, 1)))
stopifnot(length(prediction) == nrow(split$test), all(prediction %in% classes))
cat("Image generation, split and evaluation tests passed.\n")
