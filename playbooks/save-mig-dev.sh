#!/bin/bash
pat='MIG-GPU-[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}/[0-9]/[0-9]'
s=$(nvidia-smi -L | grep MIG-GPU)
rm ~/cuda-devices.txt
rm ~/jupyter-sessions.txt
port=9000
nvidia-smi -L | grep MIG-GPU | while read -r line ; do
  [[ $line =~ $pat ]]
  nohup docker run -p $port:8888 --mount source=/$NFS_EXPORT_PATH,target=/$NFS_EXPORT_PATH --gpus 'device='$BASH_REMATCH $DOCKER_IMAGE_NAME &
  echo $BASH_REMATCH >> ~/cuda-devices.txt
  ((port++))
done
