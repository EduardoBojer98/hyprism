# Module: ai

Run language models on your own computer with Ollama, on the graphics card when you have one.

- **On when:** only when you ask: `./install.sh --with ai`.
- **Adds:** `ollama`; on a computer with an NVIDIA card also its CUDA build and the NVIDIA container toolkit
  (Arch; on Fedora the toolkit comes from NVIDIA's own repo, so it is left to you).
- **Start it when you need it** (it is not started at boot, so the graphics card can sleep):

  ```bash
  systemctl start ollama
  ```

  ```bash
  ollama run llama3.2
  ```

- **Is it on the graphics card?** While a model answers, `nvidia-smi` lists `ollama` and its memory, and the
  bar's system-info item shows the second card awake. `ollama ps` says "100% GPU" when the whole model fits.
- **Memory:** a model needs about its file size in video memory. With 4 GB, 3B-parameter models fit entirely;
  larger ones spill to the processor and get slow.
- **Stop it** to let the card power off again: `systemctl stop ollama`.
- **Containers with the GPU** (Arch): `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi`
  after `sudo nvidia-ctk runtime configure --runtime=docker` and a Docker restart.
- **Tested on:** package names on Arch and Fedora; run on the owner's laptop (see the manual checklist).
