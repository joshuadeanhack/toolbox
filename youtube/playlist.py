import subprocess
import json
import sys
from dataclasses import dataclass
from typing import Iterator


@dataclass
class Video:
    index: int
    title: str
    id: str


def run_ytdlp_command(playlist_url: str):
    command = ["yt-dlp", "-j", "--flat-playlist", playlist_url]
    process = subprocess.run(command, capture_output=True, text=True)
    return process.stdout


def parse_json_output(output: str) -> Iterator[dict]:
    lines = output.splitlines()
    for line in lines:
        yield json.loads(line)


def create_video_objects(video_dicts: Iterator[dict]) -> Iterator[Video]:
    for i, video_dict in enumerate(video_dicts):
        yield Video(index=i+1, title=video_dict["title"], id=video_dict["id"])


def print_video_info(videos: Iterator[Video]):
    for video in videos:
        print(f'{video.index}: {video.title} (ID: {video.id})')


def main():
    if len(sys.argv) != 2:
        print("Usage: python playlist.py <playlist_url>")
        sys.exit(1)

    playlist_url = sys.argv[1]

    ytdlp_output = run_ytdlp_command(playlist_url)
    video_dicts = parse_json_output(ytdlp_output)
    videos = create_video_objects(video_dicts)

    print_video_info(videos)


if __name__ == "__main__":
    main()
