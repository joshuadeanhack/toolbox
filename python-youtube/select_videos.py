import subprocess
import json
import sys
import argparse
from dataclasses import dataclass, field
from typing import Iterator, List


@dataclass
class Video:
    index: int
    title: str
    id: str
    selected: bool = field(default=True)

def parse_arguments():
    parser = argparse.ArgumentParser(description="Process YouTube playlist.")
    parser.add_argument('playlist_url', type=str, help="YouTube playlist URL")
    parser.add_argument('--deselect', action='store_true', help="Deselect all videos at start")
    return parser.parse_args()

# Runs yt-dlp command on the given playlist URL and returns JSON output as a string
def run_ytdlp_command(playlist_url: str) -> str:
    command = ["yt-dlp", "-j", "--flat-playlist", playlist_url]
    process = subprocess.run(command, capture_output=True, text=True)
    return process.stdout

# Parses the JSON output from yt-dlp, returning each video's data as a dictionary
def parse_json_output(output: str) -> Iterator[dict]:
    lines = output.splitlines()
    for line in lines:
        yield json.loads(line)

# Converts a list of video data dictionaries into a list of Video objects
def create_video_objects(video_dicts: Iterator[dict]) -> List[Video]:
    videos = []
    for i, video_dict in enumerate(video_dicts):
        title = video_dict["title"]
        video_id = video_dict["id"]
        video = Video(index=i+1, title=title, id=video_id)
        videos.append(video)
    return videos

def deselect_all_videos(videos: List[Video]) -> None:
    for video in videos:
        video.selected = False

def print_selected_videos(videos: List[Video]) -> None:
    for video in videos:
        if video.selected:  
            print(f'{video.index}: {video.title} (ID: {video.id})')

def print_all_videos(videos: List[Video]):
    for video in videos:
        print(f'{video.index}: {video.title} (ID: {video.id})')

def print_download_commands(videos: List[Video]) -> None:
    print("To download the selected videos, run the following commands:")
    for video in videos:
        if video.selected:
            print(f'yt-dlp.exe https://www.youtube.com/watch?v={video.id}')


# Handles user interactions for selecting, deselecting, and viewing videos
def handle_user_input(videos: List[Video]) -> None:
    while True:
        print()
        print("===================")
        print("Enter a command:")
        print("1: Re-Select a video")
        print("2: Deselect a video")
        print("3: Show videos")
        print("4: Print Download List")
        print("5: Quit")

        command = input("Input: ")

        if command == '1':
            video_index = int(input("Enter the video index to select: ")) - 1
            if 0 <= video_index < len(videos):
                videos[video_index].selected = True
        elif command == '2':
            video_index = int(input("Enter the video index to deselect: ")) - 1
            if 0 <= video_index < len(videos):
                videos[video_index].selected = False
        elif command == '3':
            print_selected_videos(videos)
        elif command == '4':
            print_download_commands(videos)
        elif command == '5':
            break
        else:
            print("Invalid command. Please enter a number from 1 to 4.")


def main():
    
    args = parse_arguments()
    
    try:
        playlist_url = args.playlist_url
        ytdlp_output = run_ytdlp_command(playlist_url)
        video_dicts = parse_json_output(ytdlp_output)
    except Exception as e:
        print("Error: ")
        print(e)
        sys.exit(1)
    
    videos = create_video_objects(video_dicts)

    if videos:
        if args.deselect:
            deselect_all_videos(videos)
        print("Videos found: ")
        print_all_videos(videos)
        handle_user_input(videos)
    
    print("Thanks for using the tool! Bye now :)")
    sys.exit(0)

if __name__ == "__main__":
    main()