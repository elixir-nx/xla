# Environment variables passed via elixir_make
# ROOT_DIR
# BUILD_ARCHIVE
# BUILD_INTERNAL_FLAGS

# System vars
TEMP ?= $(HOME)/.cache

# Public configuration
BUILD_MODE ?= opt # can also be dbg
BUILD_CACHE ?= $(TEMP)/xla_extension
OPENXLA_GIT_REPO ?= https://github.com/openxla/xla.git

OPENXLA_GIT_REV ?= fd58925adee147d38c25a085354e15427a12d00a

# Private configuration
BAZEL_FLAGS = --define "framework_shared_object=false" -c $(BUILD_MODE)

OPENXLA_NS = xla-$(OPENXLA_GIT_REV)
OPENXLA_DIR = $(BUILD_CACHE)/$(OPENXLA_NS)
OPENXLA_XLA_EXTENSION_NS = xla/extension
OPENXLA_XLA_EXTENSION_DIR = $(OPENXLA_DIR)/$(OPENXLA_XLA_EXTENSION_NS)
OPENXLA_XLA_BUILD_ARCHIVE = $(OPENXLA_DIR)/bazel-bin/$(OPENXLA_XLA_EXTENSION_NS)/xla_extension.tar.gz

$(BUILD_ARCHIVE): $(OPENXLA_DIR) extension/BUILD
	rm -f $(OPENXLA_XLA_EXTENSION_DIR) && \
		ln -s "$(ROOT_DIR)/extension" $(OPENXLA_XLA_EXTENSION_DIR) && \
		cd $(OPENXLA_DIR) && \
		bazel build $(BAZEL_FLAGS) $(BUILD_FLAGS) $(BUILD_INTERNAL_FLAGS) //$(OPENXLA_XLA_EXTENSION_NS):xla_extension && \
		mkdir -p $(dir $(BUILD_ARCHIVE)) && \
		cp -f $(OPENXLA_XLA_BUILD_ARCHIVE) $(BUILD_ARCHIVE)

# Clones OPENXLA
$(OPENXLA_DIR):
	mkdir -p $(OPENXLA_DIR) && \
	  cp -r extension/patches $(OPENXLA_DIR) && \
		cd $(OPENXLA_DIR) && \
		git init && \
		git remote add origin $(OPENXLA_GIT_REPO) && \
		git fetch --depth 1 origin $(OPENXLA_GIT_REV) && \
		git checkout FETCH_HEAD && \
		bash patches/apply.sh && \
		rm $(OPENXLA_DIR)/.bazelversion

# Print OPENXLA Dir
PTD:
	@ echo $(OPENXLA_DIR)

clean:
	cd $(OPENXLA_DIR) && bazel clean --expunge
	rm -f $(OPENXLA_XLA_EXTENSION_DIR)
	rm -rf $(OPENXLA_DIR)
	rm -rf $(TARGET_DIR)
