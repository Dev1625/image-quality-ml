source("R/quality.R")

data <- make_data()
split <- split_scenes(data, seed = 85)
dev <- split_scenes(split$train, seed = 81)

simple_tree <- fit_tree(dev$train, base_features)
edge_tree <- fit_tree(dev$train)
simple <- scores(dev$test$label, predict(simple_tree, dev$test, type = "class"))
with_edge <- scores(dev$test$label, predict(edge_tree, dev$test, type = "class"))
chosen <- if (with_edge$balanced_accuracy > simple$balanced_accuracy) features else base_features

tree <- fit_tree(split$train, chosen)
prediction <- predict(tree, split$test, type = "class")
majority <- names(which.max(table(split$train$label)))
baseline <- scores(split$test$label, rep(majority, nrow(split$test)))
model <- scores(split$test$label, prediction)

cat(sprintf("Validation: %d images from %d scenes\n", nrow(dev$test),
            length(unique(dev$test$scene))))
cat(sprintf("Basic features: %.1f%% balanced accuracy\n", 100 * simple$balanced_accuracy))
cat(sprintf("With peak-edge ratio: %.1f%% balanced accuracy\n\n", 100 * with_edge$balanced_accuracy))
cat(sprintf("Refit: %d images from %d scenes\n", nrow(split$train),
            length(unique(split$train$scene))))
cat(sprintf("Final test: %d images from %d scenes\n\n", nrow(split$test),
            length(unique(split$test$scene))))
cat(sprintf("Majority baseline balanced accuracy: %.1f%%\n", 100 * baseline$balanced_accuracy))
cat(sprintf("Decision tree balanced accuracy:     %.1f%%\n\n", 100 * model$balanced_accuracy))
print(model$confusion)
cat("\nRecall by class:\n")
print(round(model$recall, 3))
cat("\nTree rules:\n")
print(tree)
