from ultralytics import YOLO
import cv2

model = YOLO("yolov8n.pt")  # auto-downloads on first run

def detect_objects(image_np):
    results = model(image_np)
    detections = []
    for r in results:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            label = model.names[int(box.cls[0])]
            conf = float(box.conf[0])
            detections.append({
                "label": label,
                "confidence": round(conf, 2),
                "box": [x1, y1, x2, y2]
            })
    return detections