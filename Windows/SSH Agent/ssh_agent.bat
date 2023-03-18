@echo off
title ssh agent

gsudo.exe PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './ssh_agent.ps1'"