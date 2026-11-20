"""Refresh the site's pictures from a published screenshot run (story 8.12: the words and pictures agree).

Reads the App Store pictures on the `appstore-screenshots` branch (written by publish-screenshots.yml at the ship)
and writes site/img/shot-*.webp at the sizes the page uses. Run at the ship, before merging the site PR:
  git fetch origin appstore-screenshots && python3 scripts/site_shots.py
Writes files only; it deploys nothing by itself."""
import io
import subprocess
from PIL import Image

BRANCH = "origin/appstore-screenshots"
# site file: (source picture on the branch, width)
SHOTS = {
    "shot-home.webp": ("iphone/iPhone-1-home.png", 640),
    "shot-now.webp": ("iphone/iPhone-2-now.png", 640),
    "shot-pop.webp": ("iphone/iPhone-6-pop.png", 640),
    "shot-unicorn.webp": ("iphone/iPhone-4-unicorn.png", 640),
    "shot-ipad.webp": ("ipad/iPad-1-home.png", 960),
    "shot-late.webp": ("ipad/iPad-3-late.png", 960),
}

for out, (src, width) in SHOTS.items():
    data = subprocess.run(["git", "show", f"{BRANCH}:{src}"], check=True, capture_output=True).stdout
    im = Image.open(io.BytesIO(data)).convert("RGB")
    if im.height > im.width and "ipad" in src:
        im = im.rotate(90, expand=True)  # in case a sideways iPad frame slips through
    im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(f"site/img/{out}", "WEBP", quality=82)
    print("wrote", out, im.size)
