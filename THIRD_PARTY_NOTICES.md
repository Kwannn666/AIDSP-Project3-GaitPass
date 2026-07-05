# Third-Party Notices

This repository is MIT-licensed for original project files created by the
repository owner, unless otherwise noted.

Some included artifacts are third-party model files or derived exports. These
remain under their original upstream licenses and terms.

## Model Artifacts

| Path | Origin / Notes | License Notes |
| --- | --- | --- |
| `models/yolov8n-pose.pt` | YOLOv8n-pose model weights from the Ultralytics YOLO family. | Ultralytics YOLO is distributed under AGPL-3.0, with separate enterprise licensing available from Ultralytics. |
| `models/yolov8n-pose.onnx` | ONNX export derived from `yolov8n-pose.pt`. | Same upstream model/license considerations as the source YOLOv8n-pose weights. |
| `models/gaitgraph_resgcn-n39-r8_coco_seq_60.pth` | GaitGraph-related checkpoint included for gait-recognition experimentation. | Verify and preserve the original upstream license before redistribution or commercial use. |

## Large Deployment Artifact

`gaitpass-jetson-image.tar.gz` is intentionally excluded from Git because it is
too large for normal repository storage. If published separately as a release
asset or external download, its included third-party packages and model files
should be distributed with their corresponding notices.
