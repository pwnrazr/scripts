# Mount VHDX and setup zram

I use ZFS VHDX vdisks to store ROM source instead of inside WSL since it wouldn't fit and I would like to use filesystem compression to fit it in my SSD.
Also I use zram since I run out of memory often when building Android ROM