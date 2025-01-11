#!/usr/bin/env python

import requests
from PIL import Image
from io import BytesIO
import os
import logging
import subprocess
from datetime import datetime, timedelta
import random
import json
import shutil
import argparse

logging.basicConfig(filename=os.path.expanduser('~/gundam_wallpaper.log'), level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')

BACKGROUND_FOLDER = os.path.expanduser('~/backgrounds')
CACHE_FILE = os.path.join(BACKGROUND_FOLDER, 'wallpaper_cache.json')

WALLHAVEN_API_URL = "https://wallhaven.cc/api/v1/search"
WALLHAVEN_API_KEY = "e91qhQPJwzUe9Alynv1NiWquByHXYpeu"

def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, 'r') as f:
            return json.load(f)
    return {'last_update': None, 'wallpapers': []}

def save_cache(cache):
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f)

def is_waifu2x_available():
    waifu2x_path = shutil.which("waifu2x-ncnn-vulkan")
    if waifu2x_path:
        logging.info(f"Waifu2x found at: {waifu2x_path}")
        return waifu2x_path
    else:
        logging.warning("waifu2x-ncnn-vulkan not found. Falling back to standard resizing.")
        return None

def upscale_with_waifu2x(input_path, output_path, waifu2x_path, scale=2):
    try:
        subprocess.run([
            waifu2x_path,
            "-i", input_path,
            "-o", output_path,
            "-s", str(scale),
            "-n", "0"
        ], check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"Error upscaling image with Waifu2x: {e}")
        logging.error(f"Waifu2x stderr: {e.stderr}")
        return False

def fetch_wallpapers(page=1):
    params = {
        "apikey": WALLHAVEN_API_KEY,
        "q": "gundam",
        "categories": "111",
        "purity": "100",
        "sorting": "random",
        "page": page,
        "atleast": "1920x1080"
    }
    try:
        response = requests.get(WALLHAVEN_API_URL, params=params)
        response.raise_for_status()
        data = response.json()
        return [wallpaper['path'] for wallpaper in data['data']]
    except requests.RequestException as e:
        logging.error(f"Error fetching wallpapers from Wallhaven: {e}")
        return []

def resize_and_crop(img, target_width, target_height):
    target_ratio = target_width / target_height
    img_ratio = img.width / img.height

    if img_ratio > target_ratio:
        new_width = int(img.height * target_ratio)
        offset = (img.width - new_width) // 2
        img = img.crop((offset, 0, offset + new_width, img.height))
    elif img_ratio < target_ratio:
        new_height = int(img.width / target_ratio)
        offset = (img.height - new_height) // 2
        img = img.crop((0, offset, img.width, offset + new_height))

    img = img.resize((target_width, target_height), Image.LANCZOS)
    return img

def download_and_save_wallpaper(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))

        target_width, target_height = 1920, 1080
        img = resize_and_crop(img, target_width, target_height)

        filename = f"gundam_wallpaper_{datetime.now().strftime('%Y%m%d%H%M%S')}.jpg"
        filepath = os.path.join(BACKGROUND_FOLDER, filename)

        waifu2x_path = is_waifu2x_available()
        if waifu2x_path:
            temp_path = os.path.join(BACKGROUND_FOLDER, "temp_wallpaper.jpg")
            img.save(temp_path)
            if upscale_with_waifu2x(temp_path, filepath, waifu2x_path):
                os.remove(temp_path)
                logging.info(f"Saved upscaled wallpaper: {filepath}")
                return filepath

        img.save(filepath)
        logging.info(f"Saved resized and cropped wallpaper: {filepath}")
        return filepath
    except Exception as e:
        logging.error(f"Error downloading or saving image: {e}")
        return None

def set_wallpaper(filepath):
    try:
        # Use feh to set the wallpaper
        subprocess.run(["feh", "--bg-fill", filepath], check=True)
        logging.info(f"Wallpaper set successfully: {filepath}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to set wallpaper: {e}")

def fetch_new_wallpapers(num_wallpapers=5):
    all_wallpapers = []
    page = 1
    while len(all_wallpapers) < num_wallpapers:
        wallpaper_urls = fetch_wallpapers(page)
        if not wallpaper_urls:
            break
        all_wallpapers.extend(wallpaper_urls)
        page += 1

    random.shuffle(all_wallpapers)
    selected_wallpapers = all_wallpapers[:num_wallpapers]
    downloaded_wallpapers = []
    for url in selected_wallpapers:
        wallpaper_path = download_and_save_wallpaper(url)
        if wallpaper_path:
            downloaded_wallpapers.append(wallpaper_path)
            logging.info(f"Downloaded wallpaper: {wallpaper_path}")
        else:
            logging.error(f"Failed to download wallpaper: {url}")
    if downloaded_wallpapers:
        set_wallpaper(downloaded_wallpapers[-1])  # Set the last downloaded wallpaper
    return downloaded_wallpapers

def main():
    parser = argparse.ArgumentParser(description="Gundam Wallpaper Updater")
    parser.add_argument('-f', '--force', action='store_true', help="Force fetch new wallpapers")
    parser.add_argument('-n', '--number', type=int, default=5, help="Number of wallpapers to fetch when forcing")
    args = parser.parse_args()

    try:
        os.makedirs(BACKGROUND_FOLDER, exist_ok=True)

        if args.force:
            logging.info(f"Forcing new wallpaper fetch (requesting {args.number} wallpapers)")
            new_wallpapers = fetch_new_wallpapers(args.number)
            if new_wallpapers:
                logging.info(f"Successfully fetched {len(new_wallpapers)} new wallpapers")
                return
            else:
                logging.error("Failed to fetch new wallpapers")

        cache = load_cache()
        current_time = datetime.now()

        if not cache['last_update'] or (current_time - datetime.fromisoformat(cache['last_update'])) > timedelta(days=7) or not cache['wallpapers']:
            wallpaper_urls = fetch_wallpapers()
            cache['wallpapers'] = wallpaper_urls
            cache['last_update'] = current_time.isoformat()
            save_cache(cache)

        if cache['wallpapers']:
            url = random.choice(cache['wallpapers'])
            wallpaper_path = download_and_save_wallpaper(url)
            if wallpaper_path:
                set_wallpaper(wallpaper_path)
            else:
                logging.error("Failed to download and save wallpaper")
        else:
            logging.error("No wallpapers found in cache")
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)

if __name__ == "__main__":
    main()
