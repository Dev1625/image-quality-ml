source("R/quality.R")

data <- make_data()
grouped <- split_scenes(data, seed = 85)

# Try a row split with the same number of test images.
set.seed(85)
test_rows <- sample(seq_len(nrow(data)), nrow(grouped$test))
by_row <- list(train = data[-test_rows, ], test = data[test_rows, ])

check_split <- function(split) {
  seen <- split$test$scene %in% split$train$scene
  tree <- fit_tree(split$train)
  prediction <- predict(tree, split$test, type = "class")
  result <- scores(split$test$label, prediction)
  c(
    test_images = nrow(split$test),
    test_scenes = length(unique(split$test$scene)),
    test_images_from_seen_scenes = sum(seen),
    balanced_accuracy = round(result$balanced_accuracy, 3)
  )
}

comparison <- rbind(by_row = check_split(by_row), by_scene = check_split(grouped))
print(comparison)
stopifnot(comparison["by_row", "test_images_from_seen_scenes"] > 0)
stopifnot(comparison["by_scene", "test_images_from_seen_scenes"] == 0)
