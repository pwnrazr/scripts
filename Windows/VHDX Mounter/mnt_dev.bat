@echo off
title Mount vhdx disks

gsudo.exe PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './vhdx_mounter.ps1'"
