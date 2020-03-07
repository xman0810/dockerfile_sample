DOCKER=docker
DOCKER_REPOSITORY=mlir-tpu/mlir-env
DOCKER_REGISTRY=10.34.33.3:4567
IMAGE_NAME=mlir-sdk:cpu

X11_DISPLAY=--env DISPLAY=$(DISPLAY) \
	--env="QT_X11_NO_MITSHM=1" \
	-v /tmp/.X11-unix:/tmp/.X11-unix:ro

# MODEL_PATH
# DATASET_PATH
include config.inc
MOUNT_DIR=-v `pwd`/data/models:/workspace/data/models \
          -v `pwd`/data/dataset_zoo:/workspace/data/dataset_zoo

MOUNT_WEBCAM=--device /dev/video0:/dev/video0

base_image=ubuntu:18.04
ifeq ($(TARGET), GPU)
  base_image=nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04
  IMAGE_NAME=mlir-sdk:gpu
endif

setup:
	rm -rf ./data/*
	rm -rf ./install/*
	rm -rf ./regression/*
	ln -s $(MODEL_PATH) ./data/models
	ln -s $(DATASET_PATH) ./data/dataset_zoo
	cp -r $(INSTALL_PATH) ./
	cp -r $(REGRESSION_PATH) ./
	cp $(ENVSETUP_PATH) ./regression

build:
	@echo "start build image........."
	@echo "base image is $(base_image)"
	$(DOCKER) build -t $(IMAGE_NAME) --build-arg base_image=$(base_image) -f ./Dockerfile.dev .

login:
	docker login ${DOCKER_REGISTRY}
# please login docker registry before you push or pull
# Refer to the setting in http://10.34.33.3:8480/toolchain/bmtap2/wikis/home

push:
	$(DOCKER) push $(IMAGE_NAME)

pull:
	$(DOCKER) pull $(IMAGE_NAME)

bash:
	$(DOCKER) run -it -w /workspace --privileged --rm  $(MOUNT_WEBCAM) $(MOUNT_DIR) --net=host $(IMAGE_NAME) bash

x11:
	xhost +
	$(DOCKER) run -it -w /workspace --privileged --rm $(MOUNT_DIR) $(X11_DISPLAY) $(MOUNT_WEBCAM) --net=host $(IMAGE_NAME) bash
	xhost -

clean:
	rm -rf ./data/*
	rm -rf ./install/*
	rm -rf ./regression/*
