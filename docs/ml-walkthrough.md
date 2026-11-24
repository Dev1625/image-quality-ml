# Walk through the image QC model

Start at the repository root with R and `rpart` installed. You'll look at what goes into the model, make a prediction, and check what your validation split actually measures. Each image in this exercise is generated. This is a portfolio tutorial built with AI assistance.

## 1. Turn pixels into a row of features

Open `R` and run these lines. `make_scene` makes a matrix of pixel intensities. `capture_image` creates a noisy capture with a label. Use `measure_image` to see what the model gets for each capture.

```r
source("R/quality.R")
set.seed(24)
scene <- make_scene()
clean <- capture_image(scene, "clean")
blur <- capture_image(scene, "blur")
dim(clean)
round(rbind(clean = measure_image(clean), blur = measure_image(blur)), 3)
```

The tree sees one row per capture. `edge_strength` averages changes between neighboring pixels. `edge_peak_ratio` asks how big the strongest few changes are relative to that average. Compare both columns. Noise and brightness also vary in these captures, so one pair of images is too little evidence to choose a feature.

## 2. Hold out complete scenes

The generator makes multiple captures of the same scene. Keep every version of a scene together when you split the data.

```r
data <- make_data()
split <- split_scenes(data, seed = 85)
table(split$train$label)
table(split$test$label)
intersect(split$train$scene, split$test$scene)
```

The intersection should be empty. From the shell, run `Rscript scripts/check-splits.R` to compare a row split with a scene split. Both test sets have 270 images. The row split puts variations of the same scene on both sides. Even if the accuracy gap is small, those two scores answer different questions. Use the scene split to estimate performance on unseen scenes.

## 3. Fit the tree and look at errors

```r
tree <- fit_tree(split$train)
guess <- predict(tree, split$test, type = "class")
result <- scores(split$test$label, guess)
result$confusion
round(result$recall, 3)
round(result$balanced_accuracy, 3)
```

The confusion matrix puts the actual labels in rows. Read the `clean` row sideways to see what happens to clean captures. In the default run, 22 of 90 clean images are flagged as blur. Balanced accuracy averages recall across labels, so the overall score can look decent even while clean images cause false alarms.

## Try one change

Try dropping `bright_share`, which counts nearly white pixels. Predict which class will suffer most, then compare the recall values on the same validation subset. This exercise uses only development scenes.

```r
dev <- split_scenes(split$train, seed = 81)
full <- fit_tree(dev$train)
without <- fit_tree(dev$train, setdiff(features, "bright_share"))
full_validation <- scores(dev$test$label, predict(full, dev$test, type = "class"))
without_validation <- scores(dev$test$label, predict(without, dev$test, type = "class"))
round(rbind(full = full_validation$recall, without_bright_share = without_validation$recall), 3)
```

Keep the held-out test split for reporting the final model after feature choices are fixed. `Rscript run.R` shows that order in one script.

For a deeper check, run `Rscript tests/run-tests.R`. It checks repeatability, split separation and whether the metrics count every prediction.
