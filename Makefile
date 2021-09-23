# Environment variables passed via elixir_make
# ROOT_DIR
# BUILD_ARCHIVE
# BUILD_INTERNAL_FLAGS

# System vars
TEMP ?= $(HOME)/.cache

# Public configuration
BUILD_MODE ?= opt # can also be dbg
BUILD_CACHE ?= $(TEMP)/xla_extension
TENSORFLOW_GIT_REPO ?= https://github.com/tensorflow/tensorflow.git

# Tensorflow 2.6.0
TENSORFLOW_GIT_REV ?= 919f693420e35d00c8d0a42100837ae3718f7927

# Private configuration
BAZEL_FLAGS = --define "framework_shared_object=false" -c $(BUILD_MODE)

TENSORFLOW_NS = tf-$(TENSORFLOW_GIT_REV)
TENSORFLOW_DIR = $(BUILD_CACHE)/$(TENSORFLOW_NS)
TENSORFLOW_XLA_EXTENSION_NS = tensorflow/compiler/xla/extension
TENSORFLOW_XLA_EXTENSION_DIR = $(TENSORFLOW_DIR)/$(TENSORFLOW_XLA_EXTENSION_NS)
TENSORFLOW_XLA_BUILD_ARCHIVE = $(TENSORFLOW_DIR)/bazel-bin/$(TENSORFLOW_XLA_EXTENSION_NS)/xla_extension.tar.gz

$(BUILD_ARCHIVE): $(TENSORFLOW_DIR) extension/BUILD
	rm -f $(TENSORFLOW_XLA_EXTENSION_DIR) && \
		ln -s "$(ROOT_DIR)/extension" $(TENSORFLOW_XLA_EXTENSION_DIR) && \
		cd $(TENSORFLOW_DIR) && \
		bazel build $(BAZEL_FLAGS) $(BUILD_FLAGS) $(BUILD_INTERNAL_FLAGS) //$(TENSORFLOW_XLA_EXTENSION_NS):xla_extension && \
		mkdir -p $(dir $(BUILD_ARCHIVE)) && \
		cp -f $(TENSORFLOW_XLA_BUILD_ARCHIVE) $(BUILD_ARCHIVE)

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
	rm -rf $(TARGET_DIR)
