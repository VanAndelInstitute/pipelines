## Pre-requisites

A python/pip installation is required. Then tensorflow and TFFP can be 
installed. 

```{bash}
pip install --upgrade "tensorflow"
git clone https://github.com/googlecodelabs/tensorflow-for-poets-2
cd tensorflow-for-poets-2
```

The classification script (`label_image.py`) and training script (`retrain.py`) 
were designed for tensorflow 1.x, so need some tweaks to be compatible with 
tensorflow 2.x. Also, the classification script needs adjustment output the 
data we want. So we update them as follows. (Updated scripts are included in 
this repo)

First, retrain.py:

```
--- orig/retrain.py	
+++ retrain.py	
@@ -106,7 +106,7 @@

 import numpy as np
 from six.moves import urllib
-import tensorflow as tf
+import tensorflow.compat.v1 as tf

```

And then `label_image.py`:
```
--- orig/label_image.py
+++ label_image.py
@@ -22,7 +22,8 @@
 import time

 import numpy as np
-import tensorflow as tf
+import tensorflow.compat.v1 as tf
+tf.compat.v1.disable_eager_execution()

 def load_graph(model_file):
   graph = tf.Graph()
@@ -68,14 +69,14 @@
   return label

 if __name__ == "__main__":
-  file_name = "tf_files/flower_photos/daisy/3475870145_685a19116d.jpg"
+#  file_name = "tf_files/flower_photos/daisy/3475870145_685a19116d.jpg"
   model_file = "tf_files/retrained_graph.pb"
   label_file = "tf_files/retrained_labels.txt"
-  input_height = 224
-  input_width = 224
+  input_height = 299
+  input_width = 299
   input_mean = 128
   input_std = 128
-  input_layer = "input"
+  input_layer = "Mul"
   output_layer = "final_result"

   parser = argparse.ArgumentParser()
@@ -132,6 +133,8 @@
   labels = load_labels(label_file)

   print('\nEvaluation time (1-image): {:.3f}s\n'.format(end-start))
-  template = "{} (score={:0.5f})"
+  print('\nRESULTS:\n')
+  print('Label\tScore')
+  template = "{}\t{:0.5f}"
   for i in top_k:
     print(template.format(labels[i], results[i]))
     
```

## Usage

Copy the classify.sh script provided here to `tensorflow_for_poets2`. Then `cd`
to that directory, and `chmod` that script to be executavle. Nex create a 
subdirectory of `tf_files` to put your training
images in. In that directory, put training images, in subdirectories named after
the labels each image belongs to. For example, I created
`tf_files/Cells/Differentiated`, `tf_files/Cells/Undifferentiated`, etc. for the
several labels I wanted to train for and then populated those directories with
training images (that had been manually classified by a human--in this case,
me.)

Thence...

```
IMAGE_SIZE=224
ARCHITECTURE="inception_v3"

# optional
tensorboard --logdir tf_files/training_summaries &

# adjust --image_dir to reflect the location of your training folders
python -m scripts.retrain \
  --bottleneck_dir=tf_files/bottlenecks \
  --how_many_training_steps=2000 \
  --model_dir=tf_files/models/ \
  --summaries_dir=tf_files/training_summaries/"${ARCHITECTURE}" \
  --output_graph=tf_files/retrained_graph.pb \
  --output_labels=tf_files/retrained_labels.txt \
  --architecture="${ARCHITECTURE}" \
  --image_dir=tf_files/Cells \
  --test_batch_size=50 \
  --validation_batch_size=30  


  # --train_batch_size=-1 \
  # --test_batch_size=50 \
  # --learning_rate=0.005

```

Note that `image_dir` is the top level directory of your training set that contains the subdirectories for each label of interest.

Then create a folder name `incoming` for images to be classified. Upload images there and thence:

```
find incoming/*.jpg | xargs -n1 ./classify.sh > results.tab

```

Finally, the output can be parsed in R. The following gives an example (in this 
case, the image types were "m1" through "m4". The below will need to be adjusted 
for other image labels.)

```
lines <- readLines("tensorflow-for-poets-2/results.tab")

first = TRUE
result <- list()
res <- matrix(ncol=4, nrow=0)
for(l in lines) {
  if(grepl("^m", l)) {
    lab <- gsub("\\t.*", "", l)
    val <- as.numeric(gsub(".*\\t", "", l))
    result[[lab]] <- val
    print(result)
  }
  if(grepl("RESULTS:", l)) {
    if(first){
      first <- FALSE
    } else {
      res <- rbind(res, c(result$m1, result$m2, result$m3, result$m4))
      result <- list()
    }
  }
}

```
