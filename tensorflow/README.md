## Tensorflow

Image classification via deep learning.

Pre-requisites

```
pip install --upgrade "tensorflow==1.7.*"
git clone https://github.com/googlecodelabs/tensorflow-for-poets-2
cd tensorflow-for-poets-2
```

The classification script needs a little tweak:

```
diff --git a/scripts/label_image.py b/scripts/label_image.py
index 214c4ec..5323cb6 100644
--- a/scripts/label_image.py
+++ b/scripts/label_image.py
@@ -68,14 +68,13 @@ def load_labels(label_file):
   return label

 if __name__ == "__main__":
-  file_name = "tf_files/flower_photos/daisy/3475870145_685a19116d.jpg"
   model_file = "tf_files/retrained_graph.pb"
   label_file = "tf_files/retrained_labels.txt"
-  input_height = 224
-  input_width = 224
+  input_height = 299
+  input_width = 299
+  input_layer = "Mul"
   input_mean = 128
   input_std = 128
-  input_layer = "input"
   output_layer = "final_result"

   parser = argparse.ArgumentParser()
@@ -132,6 +131,8 @@ if __name__ == "__main__":
   labels = load_labels(label_file)

   print('\nEvaluation time (1-image): {:.3f}s\n'.format(end-start))
-  template = "{} (score={:0.5f})"
+  print('\nRESULTS:\n')
+  print('Label\tScore')
+  template = "{}\t{:0.5f}"
   for i in top_k:
     print(template.format(labels[i], results[i]))
     
```
Usage:

Copy the classify.sh script here to `tensorflow_for_poets2`. Then `cd` to that directory, and create a subdirectory of `tf_files` to put your training images in. In that directory, put training images, in subdirectories named after the labels each image belongs to. For example, I created `tf_files/Cells/Differentiated`, `tf_files/Cells/Undifferentiated`, etc. for the several labels I wanted to train for and then populated those directories with training images (that had been manually classified by a human--in this case, me.)


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

