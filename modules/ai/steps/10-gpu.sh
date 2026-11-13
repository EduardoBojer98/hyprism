# shellcheck shell=bash
# NVIDIA card found: also install Ollama's CUDA build and the NVIDIA container toolkit, so models and
# containers can use the card. Skipped on computers without one.
if [[ " $(hw_get gpu.vendors) " == *" nvidia "* ]]; then
    install_names ollama-gpu nvidia-container-toolkit
else
    say "No NVIDIA card: Ollama runs on the processor (and on AMD/Intel graphics where its own build supports them)."
fi
