# System vars
TEMP ?= $(HOME)/.cache

# Public configuration
BUILD_MODE ?= opt # can also be dbg
BUILD_CACHE ?= $(TEMP)/xla_extension
TENSORFLOW_GIT_REPO ?= https://github.com/tensorflow/tensorflow.git

# TODO: Should this instead be a stable version source?
# e.g. instead use wget to download tagged releases
TENSORFLOW_GIT_REV ?= 54dee6dd8d47b6e597f4d3f85b6fb43fd5f50f82

# Private configuration
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TARGET_DIR = priv
TARGET_ARCHIVE = $(TARGET_DIR)/xla_extension.tar.gz
BAZEL_FLAGS = --define "framework_shared_object=false" -c $(BUILD_MODE)

TENSORFLOW_NS = tf-$(TENSORFLOW_GIT_REV)
TENSORFLOW_DIR = $(BUILD_CACHE)/$(TENSORFLOW_NS)
TENSORFLOW_XLA_EXTENSION_NS = tensorflow/compiler/xla/extension
TENSORFLOW_XLA_EXTENSION_DIR = $(TENSORFLOW_DIR)/$(TENSORFLOW_XLA_EXTENSION_NS)
TENSORFLOW_XLA_ARCHIVE = $(TENSORFLOW_DIR)/bazel-bin/$(TENSORFLOW_XLA_EXTENSION_NS)/xla_extension.tar.gz

$(TARGET_ARCHIVE): $(TENSORFLOW_XLA_ARCHIVE)
	mkdir -p $(TARGET_DIR) && cp -f $(TENSORFLOW_XLA_ARCHIVE) $(TARGET_ARCHIVE)

$(TENSORFLOW_XLA_ARCHIVE): symlinks
	cd $(TENSORFLOW_DIR) && \
		bazel build $(BAZEL_FLAGS) $(XLA_EXTENSION_FLAGS) $(XLA_EXTENSION_INTERNAL_FLAGS) //$(TENSORFLOW_XLA_EXTENSION_NS):xla_extension

symlinks: $(TENSORFLOW_DIR)
	@ rm -f $(TENSORFLOW_XLA_EXTENSION_DIR)
	@ ln -s "$(ROOT_DIR)/extension" $(TENSORFLOW_XLA_EXTENSION_DIR)

# Clones tensorflow
$(TENSORFLOW_DIR):
	mkdir -p $(TENSORFLOW_DIR) && \
		cd $(TENSORFLOW_DIR) && \
		git init && \
		git remote add origin $(TENSORFLOW_GIT_REPO) && \
		git fetch --depth 1 origin $(TENSORFLOW_GIT_REV) && \
		git checkout FETCH_HEAD

# Print Tensorflow Dir
PTD:
	@ echo $(TENSORFLOW_DIR)

clean:
	cd $(TENSORFLOW_DIR) && bazel clean --expunge
	rm -f $(TENSORFLOW_XLA_EXTENSION_DIR)
	rm -rf $(TENSORFLOW_DIR)
	rm -rf $(TARGET_DIR)/xla_extension.tar.gz
