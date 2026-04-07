from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import cv2
from app.detector import detect_objects
from app.depth import estimate_depth

app = FastAPI()

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.post("/measure")
async def measure(file: UploadFile = File(...)):
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    detections = detect_objects(image)
    depth_map = estimate_depth(image)

    results = []
    for det in detections:
        x1, y1, x2, y2 = det["box"]
        region_depth = depth_map[y1:y2, x1:x2]
        avg_depth = float(np.mean(region_depth))

        pixel_width = x2 - x1
        pixel_height = y2 - y1
        scale = 50.0 / avg_depth

        est_width_cm = round(pixel_width * scale, 1)
        est_height_cm = round(pixel_height * scale, 1)

        results.append({
            "label": det["label"],
            "confidence": det["confidence"],
            "estimated_width_cm": est_width_cm,
            "estimated_height_cm": est_height_cm,
            "avg_depth_score": round(avg_depth, 2)
        })

    return {"objects": results}