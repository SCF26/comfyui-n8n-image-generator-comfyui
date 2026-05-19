# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && cd /comfyui/custom_nodes/ComfyUI-KJNodes && (git checkout fb03b434142e9548765724f01a05ddcbf3a17be4 2>/dev/null || (git fetch origin fb03b434142e9548765724f01a05ddcbf3a17be4 --depth=1 && git checkout fb03b434142e9548765724f01a05ddcbf3a17be4) || echo "WARN: commit fb03b434142e9548765724f01a05ddcbf3a17be4 unreachable in https://github.com/kijai/ComfyUI-KJNodes, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail rgthree-comfy@1.0.2605082257 --mode remote || (echo "WARN: rgthree-comfy@1.0.2605082257 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail rgthree-comfy --mode remote)

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors' --relative-path models/checkpoints --filename 'FLUX1/flux1-dev-fp8.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
