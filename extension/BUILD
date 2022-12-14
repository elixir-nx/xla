load("@org_tensorflow//tensorflow:tensorflow.bzl", "if_cuda_or_rocm",)
load("@org_tensorflow//tensorflow:tensorflow.bzl", "if_with_tpu_support",)
load("@local_config_cuda//cuda:build_defs.bzl", "if_cuda",)
load("@local_config_rocm//rocm:build_defs.bzl", "if_rocm",)
load("@org_tensorflow//tensorflow:tensorflow.bzl", "tf_grpc_cc_dependencies",)
load("@org_tensorflow//tensorflow:tensorflow.bzl", "transitive_hdrs",)
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar",)

package(default_visibility=["//visibility:private"])

# Static library which contains dependencies necessary for building on
# top of XLA
cc_binary(
  name = "libxla_extension.so",
  deps = [
    "@com_google_absl//absl/types:span",
    "@com_google_absl//absl/types:optional",
    "@com_google_absl//absl/base:log_severity",
    "@tf_runtime//:core_runtime",
    "@tf_runtime//:hostcontext",
    "@tf_runtime//third_party/llvm_derived:unique_any",
    "@org_tensorflow//tensorflow/compiler/xla/client/lib:lu_decomposition",
    "@org_tensorflow//tensorflow/compiler/xla/client/lib:math",
    "@org_tensorflow//tensorflow/compiler/xla/client/lib:qr",
    "@org_tensorflow//tensorflow/compiler/xla/client/lib:svd",
    "@org_tensorflow//tensorflow/compiler/xla/client/lib:self_adjoint_eig",
    "@org_tensorflow//tensorflow/compiler/xla:literal",
    "@org_tensorflow//tensorflow/compiler/xla:shape_util",
    "@org_tensorflow//tensorflow/compiler/xla:status",
    "@org_tensorflow//tensorflow/compiler/xla:statusor",
    "@org_tensorflow//tensorflow/compiler/xla:types",
    "@org_tensorflow//tensorflow/compiler/xla:util",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:mlir_to_hlo",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:interpreter_device",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:pjrt_client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:pjrt_compiler",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:tfrt_cpu_pjrt_client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:pjrt_c_api_client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt:tpu_client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt/distributed",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt/gpu:se_gpu_pjrt_client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt/distributed:client",
    "@org_tensorflow//tensorflow/compiler/xla/pjrt/distributed:service",
    "@org_tensorflow//tensorflow/core:lib",
    "@org_tensorflow//tensorflow/core:lib_internal_impl",
  ]
  # GRPC Dependencies (needed for PjRt distributed)
  + tf_grpc_cc_dependencies()
  + if_with_tpu_support([
    "@org_tensorflow//tensorflow/core/tpu:tpu_api_dlsym_initializer",
  ])
  + if_cuda_or_rocm([
    "@org_tensorflow//tensorflow/compiler/xla/service:gpu_plugin",
  ])
  + if_cuda([
    "@org_tensorflow//tensorflow/compiler/xla/stream_executor:cuda_platform"
  ])
  + if_rocm([
    "@org_tensorflow//tensorflow/compiler/xla/stream_executor:rocm_platform"
  ]),
  linkopts = ["-shared"],
  linkshared = 1,
)

# Transitive hdrs gets all headers required by deps, including
# transitive dependencies, it seems though it generates a lot
# of unused headers as well
transitive_hdrs(
  name = "xla_extension_dep_headers",
  deps = [
    ":libxla_extension.so",
  ]
)

# This is the genrule used by TF install headers to correctly
# map headers into a directory structure
genrule(
  name = "xla_extension_headers",
  srcs = [
    ":xla_extension_dep_headers",
  ],
  outs = ["include"],
  cmd = """
    mkdir $@
    for f in $(SRCS); do
      d="$${f%/*}"
      d="$${d#bazel-out/*/genfiles/}"
      d="$${d#bazel-out/*/bin/}"
      if [[ $${d} == *local_config_* ]]; then
        continue
      fi
      if [[ $${d} == external* ]]; then
        extname="$${d#*external/}"
        extname="$${extname%%/*}"
        if [[ $${TF_SYSTEM_LIBS:-} == *$${extname}* ]]; then
          continue
        fi
        d="$${d#*external/farmhash_archive/src}"
        d="$${d#*external/$${extname}/}"
      fi
      # Remap third party paths
      d="$${d/third_party\\/llvm_derived\\/include\\/llvm_derived/llvm_derived}"
      # Remap llvm paths
      d="$${d/llvm\\/include\\/llvm/llvm}"
      d="$${d/llvm\\/include\\/llvm-c/llvm-c}"
      # Remap mlir paths
      d="$${d/mlir\\/include\\/mlir/mlir}"
      # Remap google path
      d="$${d/src\\/google/google}"
      # Remap grpc paths
      d="$${d/include\\/grpc/grpc}"
      # Remap tfrt paths
      d="$${d/include\\/tfrt/tfrt}"
      mkdir -p "$@/$${d}"
      cp "$${f}" "$@/$${d}/"
    done
    """,
  )

# This genrule remaps libxla_extension.so to lib/libxla_extension.so
genrule(
  name = "xla_extension_lib",
  srcs = [
    ":libxla_extension.so",
  ],
  outs = ["lib"],
  cmd = """
    mkdir $@
    mv $(location :libxla_extension.so) $@
  """
)

pkg_tar(
  name = "xla_extension",
  extension = "tar.gz",
  mode = "0644",
  package_dir = "xla_extension",
  srcs = [
    ":xla_extension_lib",
    ":xla_extension_headers",
  ],
)
