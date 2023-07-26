$vhdx = @(
	[pscustomobject]@{path="G:\wsl\yaap.vhdx";mounted="false";num="";drv=""}
	[pscustomobject]@{path="D:\wsl\dev_stuff.vhdx";mounted="false";num="";drv=""}
)

get-disk | ForEach-Object {
	for ( $i = 0; $i -ne $vhdx.count; $i++ ) {
		if($_.Location -contains $vhdx[$i].path) 
		{
			$vhdx[$i].mounted = 'true'
			$vhdx[$i].num = $_.number
			$current_disk = $vhdx[$i].path
			
			Write-Output "$current_disk already mounted"
			Write-Output ""
		}
	}
}

$current_disk = ""

for ( $i = 0; $i -ne $vhdx.count; $i++ ) 
{
	Write-Output ""
	Write-Output "############################"

	$current_disk = $vhdx[$i].path
	$current_disk_num = $vhdx[$i].num

	if($vhdx[$i].mounted -match 'false') 
	{
		Write-Output "$current_disk not mounted. Mounting..."

		$vhdx[$i].drv = "\\.\PhysicalDrive$((Mount-VHD -Path $vhdx[$i].path -PassThru | Get-Disk).Number)"

		$current_disk_drv = $vhdx[$i].drv
		Write-Output "$current_disk mounted on $current_disk_drv"
		Write-Output "Mounting $current_disk_drv on WSL"

		wsl --mount $vhdx[$i].drv --bare
		Write-Output "############################"
	} 
	else 
	{
		Write-Output "$current_disk already mounted on \\.\PhysicalDrive$current_disk_num"
		Write-Output "Mounting \\.\PhysicalDrive$current_disk_num on WSL"
		wsl --mount \\.\PhysicalDrive$current_disk_num --bare
		Write-Output "############################"
	}
}