ffmpeg -i src/output/video.avi -i src/output/audio.wav -c:v libx264 -c:a aac -movflags +faststart src/output/combined.mp4