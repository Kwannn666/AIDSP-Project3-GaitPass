# Project File Analysis

## Overview

This folder is a Jetson deployment package for a gait-based access-control
prototype. The system uses YOLOv8n-pose for person detection and 17-keypoint
pose extraction, then matches lightweight gait descriptors against a gallery to
classify an authorized user and detect tailgating.

## Included Files

| Path | Purpose | Notes |
| --- | --- | --- |
| `README.md` | Main project/deployment instructions | Describes the intended full project layout and Jetson workflow. |
| `步態辨識門禁系統.pdf` | Project report/slides | 18 pages, created in Canva. |
| `project3-demo.mp4` | Backup demo video | 1920x1080, 30 FPS, about 9.2 seconds. |
| `.env.example` | Runtime configuration template | Camera, detector, authentication, and alert settings. |
| `docker/docker-compose.jetson.yml` | Jetson container launch config | Uses host networking, NVIDIA runtime, `/dev/video0`, and mounts `models/` and `data/`. |
| `docker/Dockerfile.jetson` | Jetson image build recipe | Expects source folders such as `app/`, `scripts/`, and `requirements-jetson.txt`. |
| `docker/entrypoint.sh` | Container startup script | Starts FastAPI/Uvicorn dashboard by default. |
| `models/yolov8n-pose.onnx` | YOLOv8n-pose ONNX model | Runtime detector model. |
| `models/yolov8n-pose.pt` | YOLOv8n-pose PyTorch weights | Source/export model file. |
| `models/gaitgraph_resgcn-n39-r8_coco_seq_60.pth` | GaitGraph-related checkpoint | Included model artifact, not directly referenced by the compose file. |
| `data/gallery/gallery.npz` | Authentication gallery | Contains `person_a` and `__unknown__` gait descriptors. |
| `gaitpass-jetson-image.tar.gz` | Prebuilt Docker image export | About 5.36 GB; too large for normal GitHub Git storage. |

## Data Observations

- `gallery.npz` contains two classes: `person_a` with 5 embeddings and
  `__unknown__` with 6 embeddings.
- Each embedding is 21-dimensional `float32` and appears L2-normalized.
- The two classes are close in embedding space: the centroid cosine similarity
  between `person_a` and `__unknown__` is about 0.989.
- Because the gallery separation is weak, the system relies heavily on unknown
  rejection, voting, and hysteresis thresholds to avoid false acceptance.

## Deployment Notes

- The prebuilt image tag in `gaitpass-jetson-image.tar.gz` is
  `gaitpass-jetson:r35.4.1`.
- This package is suitable for loading and running a prepared Jetson demo.
- Rebuilding from source may fail in this folder because `app/`, `scripts/`,
  `requirements-jetson.txt`, `TRAINING.md`, and sample training clips are not
  present.
- `models/yolov8n-pose.engine` is not included, so TensorRT mode requires
  conversion on the Jetson before use.

## GitHub Upload Recommendation

The Docker image export `gaitpass-jetson-image.tar.gz` should not be committed
to a normal GitHub repository. Use one of these alternatives instead:

- Upload it as a GitHub Release asset.
- Store it with Git LFS if the account/repository supports enough quota.
- Keep it outside the repository and document the local deployment path.

