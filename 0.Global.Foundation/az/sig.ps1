#########
# Linux #
#########

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  galleryName    = "xstudio"
  definitionName = "Linux"
  versionId      = "1.0.0"
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  $gpuRender     = $false
  galleryName    = "xstudio"
  definitionName = "Linux"
  versionId      = if ($gpuRender) {"2.1.0"} else {"2.0.0"}
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  galleryName    = "xstudio"
  definitionName = "Linux"
  versionId      = "3.0.0"
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones

###########
# Windows #
###########

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  galleryName    = "xstudio"
  definitionName = "WinServer"
  versionId      = "1.0.0"
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  $gpuRender     = $false
  galleryName    = "xstudio"
  definitionName = "WinFarm"
  versionId      = if ($gpuRender) {"2.1.0"} else {"2.0.0"}
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones

$resourceGroupName   = "ArtistAnywhere.Image"
$targetExtendedZones = "WestUS=LosAngeles=2=premium_lrs"
$image = @{
  galleryName    = "xstudio"
  definitionName = "WinArtist"
  versionId      = "3.0.0"
}
az sig image-version show --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId
az sig image-version update --resource-group $resourceGroupName --gallery-name $image.galleryName --gallery-image-definition $image.definitionName --gallery-image-version $image.versionId --target-edge-zones $targetExtendedZones
