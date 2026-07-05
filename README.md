# GaitPass Jetson

Privacy-preserving gait authentication and tailgating detection for Jetson Xavier/Orin.

This folder is intentionally independent from other Docker projects such as thesis or
research containers. It uses its own image name, container name, ports, volumes, and
data folders.

## Goal

Build a small edge AI access-control prototype:

- Detect people from a USB/CSI camera.
- Track each person over time.
- Create a lightweight gait descriptor from the person's motion.
- Decide whether the person is authorized or unknown.
- Trigger a tailgating alert when a second person follows an authorized user.
- Avoid saving raw frames by default.

## Project Layout

```text
app/
  main.py              FastAPI entrypoint and MJPEG dashboard
  pipeline.py          Realtime camera -> detect -> track -> auth -> alert loop
  detector.py          YOLOv8-pose ONNX/TensorRT detector (bbox + 17 keypoints), HOG fallback
  tracker.py           Simple centroid tracker (carries keypoint sequences)
  gait_auth.py         Gallery-based gait authentication (keypoint or box features)
  tailgating.py        Virtual gate-line and tailgating rules
  privacy.py           Face/body-frame privacy helpers
  event_log.py         JSONL event logger
docker/
  Dockerfile.jetson
  docker-compose.jetson.yml
  entrypoint.sh
scripts/
  check_camera.py      Camera smoke test
  enroll_gallery.py    Build gallery embeddings from recorded clips
  run_demo.py          Local pipeline launcher
models/                Put ONNX/TensorRT/person detector weights here
data/
  gallery/             Authorized-user embeddings
  logs/                Event logs
  samples/             Optional local test clips
```

## Isolation From Thesis Environment

This project does not reference `E:\docker_projects\uav-ris` or any existing thesis
container. The compose file uses:

- `container_name: gaitpass-jetson`
- `image: gaitpass-jetson:<tag>`
- `APP_PORT=18080`
- local volumes only under this project folder

Avoid running broad Docker cleanup commands such as:

```bash
docker system prune -a --volumes
```

That command can remove unrelated images or volumes from other projects.

## Jetson Build

On the Jetson, first check the L4T/JetPack version:

```bash
cat /etc/nv_tegra_release
```

Then edit `L4T_TAG` in `.env.example` or export it before build. The default tag is
conservative for JetPack 5.x Xavier projects, but your exact device may need a
different tag.

```bash
cp .env.example .env
docker compose -f docker/docker-compose.jetson.yml --env-file .env build
docker compose -f docker/docker-compose.jetson.yml --env-file .env up
```

Open the dashboard:

```text
http://<jetson-ip>:18080
```

## First Milestones

1. Build the container on Jetson.
2. Confirm `/dev/video0` is readable.
3. Open the dashboard and check FPS.
4. Record 20-50 clips per person.
5. Run gallery enrollment.
6. Tune the authorized/unknown threshold.
7. Add a stronger detector or pose model.

## Camera Smoke Test

Inside the container:

```bash
python3 scripts/check_camera.py --source 0 --frames 120
```

## Gallery Enrollment

Put short clips into:

```text
data/samples/alice/*.mp4
data/samples/bob/*.mp4
```

Then run:

```bash
python3 scripts/enroll_gallery.py --input data/samples --output data/gallery/gallery.npz
```

For a more complete training/evaluation flow, use:

```bash
python3 scripts/train_gait_gallery.py \
  --input data/samples \
  --output data/gallery/gallery.npz \
  --report data/gallery/training_report.json \
  --shots 3
```

See `TRAINING.md` for the recommended dataset layout and threshold tuning flow.

## Pose Model (Runtime Default)

The runtime detector is COCO-pretrained YOLOv8n-pose exported to ONNX. One
forward pass returns person boxes plus 17 keypoints, which feed both tracking
and the gait features. Export on a PC (no training needed):

```bash
pip install ultralytics onnx onnxsim
yolo export model=yolov8n-pose.pt format=onnx imgsz=640 opset=12
```

Place `yolov8n-pose.onnx` under `models/` (the compose file mounts it into the
container). Smoke-test the decode path on any photo with people:

```bash
python scripts/test_onnx_detector.py --image photo.jpg --output annotated.jpg
```

If the model file is missing at runtime, the pipeline logs a warning and falls
back to the HOG baseline so the dashboard still comes up.

Fine-tuning is only needed if the doorway camera angle causes missed
detections; see `YOLO_TRAINING.md` and `colab/yolo_person_train_export_colab.py`.

## TensorRT Engine Mode

For higher FPS on Jetson, convert the pose ONNX model to a TensorRT engine:

```bash
trtexec \
  --onnx=/workspace/gaitpass/models/yolov8n-pose.onnx \
  --saveEngine=/workspace/gaitpass/models/yolov8n-pose.engine \
  --fp16
```

Then set:

```env
DETECTOR_MODE=tensorrt
MODEL_PATH=models/yolov8n-pose.engine
```

The TensorRT backend requires TensorRT Python and PyCUDA inside the container.

## Notes

The pipeline runs end to end with the ONNX pose model: detection, tracking,
keypoint-sequence gait features, gallery matching, and tailgating alerts. The
HOG/box-feature path is kept as a no-model fallback and as the report baseline
to compare against the pose-based features.

## License

Original project files in this repository are released under the MIT License.
Third-party model weights, exported model files, and other external assets
remain under their original upstream licenses. See `THIRD_PARTY_NOTICES.md`.

## 繳交版快速啟動 (For Grading)

收到繳交壓縮檔後，在 Jetson Xavier 上依序執行即可開啟展示系統。

### 1. 載入 Docker image

繳交檔內的 `gaitpass-jetson-image.tar.gz` 是已建置好的映像檔，直接載入，不需重新 build：

```bash
gunzip -c gaitpass-jetson-image.tar.gz | docker load
docker images | grep gaitpass          # 應看到 gaitpass-jetson:r35.4.1
```

### 2. 確認 gallery（認證必要前置）

dashboard 需要 `data/gallery/gallery.npz` 才能辨識 `person_a`。繳交檔已附上此檔，
確認它存在即可：

```bash
ls data/gallery/gallery.npz
```

若檔案不存在，先用附帶的樣本影片重新產生：

```bash
python3 scripts/enroll_gallery.py --input data/samples --output data/gallery/gallery.npz
```

接著啟動：

```bash
cp .env.example .env                   # 若尚未建立
docker compose -f docker/docker-compose.jetson.yml --env-file .env up
```

開啟 dashboard：`http://<jetson-ip>:18080`

### 3. 預期結果（成功判準）

dashboard 開啟後應可觀察到：

- 已註冊使用者（`person_a`）通過閘門時標示為 **authorized**。
- 其他人標示為 **unknown**。
- 當第二人緊跟在授權者後方通過閘門線時，觸發 **tailgating alert**。
- 即時影像上顯示人員框、17 點骨架關鍵點與目前 FPS。

### 4. 繳交檔內容對照

| 檔案 | 用途 |
|------|------|
| `步態辨識門禁系統.pdf` | 報告簡報 |
| `gaitpass-jetson-image.tar.gz` | 邊緣裝置上執行的 Docker image（`docker load` 還原） |
| `docker/docker-compose.jetson.yml` | 啟動容器設定 |
| `.env.example` | 環境變數範本（複製為 `.env`） |
| `models/` | YOLOv8-pose 權重 (ONNX / PT) |
| `data/gallery/gallery.npz` | 步態認證 gallery（啟動必要） |
| `data/samples/` | 樣本影片（可重建 gallery） |
| `project3-demo.mp4` | 備援展示影片（現場 demo 失敗時播放） |
