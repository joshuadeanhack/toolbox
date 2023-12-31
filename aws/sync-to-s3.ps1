# Run with powershell options -Upload -LOCAL_PATH "../Folder" etc.
param (
    [string] $AWS_PROFILE = "laptop",
    [string] $AWS_BUCKET_NAME = "jjemerald-yt",
    [string] $LOCAL_PATH = ".",  # Alternative is Get-Location
    [string] $KEY = "",  # Example use "/Film-TV/Showname"
    [switch] $Upload = $false  #pass this as a flag -Upload to actually upload the videos
)

if ($Upload -eq $false)
{
    aws --profile $AWS_PROFILE s3 sync $LOCAL_PATH s3://$AWS_BUCKET_NAME$KEY --size-only --dryrun
}
else {
    aws --profile $AWS_PROFILE s3 sync $LOCAL_PATH s3://$AWS_BUCKET_NAME$KEY --size-only
}
