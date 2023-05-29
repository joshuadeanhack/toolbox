import os
from googleapiclient.discovery import build

# You must set these environment variables to your own values
os.environ["YOUTUBE_API_SERVICE_NAME"] = "youtube"
os.environ["YOUTUBE_API_VERSION"] = "v3"
os.environ["YOUTUBE_API_KEY"] = "YOUR_YOUTUBE_API_KEY"  # Replace with your YouTube API key

playlist_id = "YOUR_PLAYLIST_ID"  # Replace with your playlist ID

def get_playlist_videos(playlist_id):
    youtube = build(
        os.environ["YOUTUBE_API_SERVICE_NAME"],
        os.environ["YOUTUBE_API_VERSION"],
        developerKey=os.environ["YOUTUBE_API_KEY"]
    )

    request = youtube.playlistItems().list(
        part="snippet",
        maxResults=25,
        playlistId=playlist_id
    )
    response = request.execute()

    for item in response['items']:
        video_title = item['snippet']['title']
        video_id = item['snippet']['resourceId']['videoId']
        print(f"Title: {video_title}, ID: {video_id}")

if __name__ == "__main__":
    get_playlist_videos(playlist_id)
