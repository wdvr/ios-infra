#!/usr/bin/env python3
"""
Generate app icons programmatically.
Creates icons for all required iOS sizes.

Usage:
    python generate_icons.py --app trivit --output ./Assets.xcassets/AppIcon.appiconset
    python generate_icons.py --app snow --output ./ios/Assets.xcassets/AppIcon.appiconset
    python generate_icons.py --app footprint --output ./ios/Assets.xcassets/AppIcon.appiconset
"""

import argparse
import json
import math
import os
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Installing Pillow package...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw


# iOS App Icon sizes (points and scales)
IOS_ICON_SIZES = [
    # iPhone
    (20, 2),
    (20, 3),
    (29, 2),
    (29, 3),
    (40, 2),
    (40, 3),
    (60, 2),
    (60, 3),
    # iPad
    (20, 1),
    (20, 2),
    (29, 1),
    (29, 2),
    (40, 1),
    (40, 2),
    (76, 1),
    (76, 2),
    (83.5, 2),
    # App Store
    (1024, 1),
]


# App-specific icon themes
APP_THEMES = {
    "trivit": {
        "background_color": (74, 144, 226),  # Blue
        "foreground_color": (255, 255, 255),  # White
        "style": "counter",
        "icon_text": "+1",
    },
    "snow": {
        "background_color": (52, 73, 94),  # Dark blue-gray
        "foreground_color": (255, 255, 255),  # White
        "style": "snowflake",
        "gradient": [(41, 128, 185), (52, 73, 94)],
    },
    "footprint": {
        "background_color": (46, 204, 113),  # Green
        "foreground_color": (255, 255, 255),  # White
        "style": "globe",
    },
}


def create_trivit_icon(size: int, theme: dict) -> Image.Image:
    """Create a Trivit-style counter icon."""
    img = Image.new("RGBA", (size, size), theme["background_color"])
    draw = ImageDraw.Draw(img)

    # Draw a simple plus sign or counter indicator
    center = size // 2
    line_length = size // 3
    line_width = max(size // 15, 2)

    # Vertical line
    draw.rectangle(
        [
            center - line_width // 2,
            center - line_length // 2,
            center + line_width // 2,
            center + line_length // 2,
        ],
        fill=theme["foreground_color"],
    )

    # Horizontal line
    draw.rectangle(
        [
            center - line_length // 2,
            center - line_width // 2,
            center + line_length // 2,
            center + line_width // 2,
        ],
        fill=theme["foreground_color"],
    )

    return img


def create_snow_icon(size: int, theme: dict) -> Image.Image:
    """Create a snow/powder-style icon with snowflake."""
    img = Image.new("RGBA", (size, size), theme["background_color"])
    draw = ImageDraw.Draw(img)

    center = size // 2
    radius = size // 3

    # Draw simplified snowflake pattern
    line_width = max(size // 20, 2)

    # 6 lines radiating from center
    for angle in range(0, 360, 60):
        rad = math.radians(angle)
        x_end = center + int(radius * math.cos(rad))
        y_end = center + int(radius * math.sin(rad))
        draw.line(
            [(center, center), (x_end, y_end)],
            fill=theme["foreground_color"],
            width=line_width,
        )

        # Small branches
        branch_len = radius // 3
        for branch_angle in [30, -30]:
            branch_rad = math.radians(angle + branch_angle)
            mid_x = center + int((radius * 0.6) * math.cos(rad))
            mid_y = center + int((radius * 0.6) * math.sin(rad))
            branch_end_x = mid_x + int(branch_len * math.cos(branch_rad))
            branch_end_y = mid_y + int(branch_len * math.sin(branch_rad))
            draw.line(
                [(mid_x, mid_y), (branch_end_x, branch_end_y)],
                fill=theme["foreground_color"],
                width=max(line_width // 2, 1),
            )

    return img


def create_footprint_icon(size: int, theme: dict) -> Image.Image:
    """Create a footprint/globe-style icon."""
    img = Image.new("RGBA", (size, size), theme["background_color"])
    draw = ImageDraw.Draw(img)

    center = size // 2
    radius = size // 3

    # Draw a simple globe outline
    line_width = max(size // 25, 2)

    # Circle
    draw.ellipse(
        [
            center - radius,
            center - radius,
            center + radius,
            center + radius,
        ],
        outline=theme["foreground_color"],
        width=line_width,
    )

    # Horizontal line (equator)
    draw.line(
        [(center - radius, center), (center + radius, center)],
        fill=theme["foreground_color"],
        width=line_width,
    )

    # Vertical ellipse (meridian)
    ellipse_width = radius // 2
    draw.ellipse(
        [
            center - ellipse_width,
            center - radius,
            center + ellipse_width,
            center + radius,
        ],
        outline=theme["foreground_color"],
        width=line_width,
    )

    # Pin marker at top-right
    pin_x = center + radius // 2
    pin_y = center - radius // 2
    pin_size = size // 10

    draw.ellipse(
        [
            pin_x - pin_size,
            pin_y - pin_size,
            pin_x + pin_size,
            pin_y + pin_size,
        ],
        fill=(231, 76, 60),  # Red pin
    )

    return img


def create_icon(app: str, size: int) -> Image.Image:
    """Create an icon for the specified app and size."""
    theme = APP_THEMES.get(app, APP_THEMES["trivit"])

    if app == "trivit":
        return create_trivit_icon(size, theme)
    elif app == "snow":
        return create_snow_icon(size, theme)
    elif app == "footprint":
        return create_footprint_icon(size, theme)
    else:
        return create_trivit_icon(size, theme)


def generate_contents_json(sizes: list[tuple]) -> dict:
    """Generate Contents.json for the icon set."""
    images = []

    for points, scale in sizes:
        pixel_size = int(points * scale)

        idiom = "universal"
        if points in [60] and scale in [2, 3]:
            idiom = "iphone"
        elif points in [76, 83.5]:
            idiom = "ipad"
        elif points == 1024:
            idiom = "ios-marketing"

        filename = f"icon_{pixel_size}x{pixel_size}.png"

        images.append(
            {
                "filename": filename,
                "idiom": idiom,
                "scale": f"{scale}x",
                "size": f"{points}x{points}",
            }
        )

    return {"images": images, "info": {"author": "ios-infra", "version": 1}}


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate iOS app icons programmatically"
    )
    parser.add_argument(
        "--app",
        choices=list(APP_THEMES.keys()),
        default="trivit",
        help="App identifier for theme selection",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output directory (AppIcon.appiconset path)",
    )
    parser.add_argument(
        "--preview-only",
        action="store_true",
        help="Only generate 1024px preview, not full set",
    )

    args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.preview_only:
        # Generate just the 1024px icon for preview
        print(f"Generating preview icon for {args.app}...")
        icon = create_icon(args.app, 1024)
        icon.save(output_dir / "icon_1024x1024.png")
        print(f"Saved preview to {output_dir / 'icon_1024x1024.png'}")
    else:
        # Generate all sizes
        print(f"Generating icon set for {args.app}...")

        generated_sizes = set()
        for points, scale in IOS_ICON_SIZES:
            pixel_size = int(points * scale)

            # Skip duplicates
            if pixel_size in generated_sizes:
                continue
            generated_sizes.add(pixel_size)

            icon = create_icon(args.app, pixel_size)
            filename = f"icon_{pixel_size}x{pixel_size}.png"
            icon.save(output_dir / filename)
            print(f"  Generated {filename}")

        # Generate Contents.json
        contents = generate_contents_json(IOS_ICON_SIZES)
        with open(output_dir / "Contents.json", "w") as f:
            json.dump(contents, f, indent=2)
        print(f"  Generated Contents.json")

        print(f"\nIcon set saved to {output_dir}")
        print(f"Total icons: {len(generated_sizes)}")


if __name__ == "__main__":
    main()
