$CurrentImage = "name:tag"
$NewName = "name2:tag2"

docker pull $CurrentImage

docker tag $CurrentImage $NewName

docker push $NewName
