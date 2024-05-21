load("//xla/stream_executor:build_defs.bzl", "if_cuda_or_rocm",)
load("@local_config_cuda//cuda:build_defs.bzl", "if_cuda",)
load("@local_config_rocm//rocm:build_defs.bzl", "if_rocm",)
load("//xla/tsl:tsl.bzl", "if_with_tpu_support")
load("//xla/tsl:tsl.bzl", "tsl_grpc_cc_dependencies",)
load("//xla/tsl:tsl.bzl", "transitive_hdrs",)
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

package(default_visibility=["//visibility:private"])

# Shared library which contains the subset of XLA required for EXLA
cc_binary(
  name = "libxla_extension.so",
  deps = [
    "//xla:xla_proto_cc_impl",
    "//xla:xla_data_proto_cc_impl",
    "//xla:autotune_results_proto_cc_impl",
    "//xla:autotuning_proto_cc_impl",
    "//xla/service:hlo_proto_cc_impl",
    "//xla/service/memory_space_assignment:memory_space_assignment_proto_cc_impl",
    "//xla/service:buffer_assignment_proto_cc_impl",
    "//xla/service/gpu:backend_configs_cc_impl",
    "//xla/service/gpu/model:hlo_op_profile_proto_cc_impl",
    "//xla/stream_executor:device_description_proto_cc_impl",
    "//xla/stream_executor:stream_executor_impl",
    "//xla/stream_executor/gpu:gpu_init_impl",
    "//xla/stream_executor/host:host_platform",
    "//xla:literal",
    "//xla:shape_util",
    "//xla:status",
    "//xla:statusor",
    "//xla:types",
    "//xla:util",
    "//xla/mlir/utils:error_util",
    "//xla/mlir_hlo",
    "//xla/mlir_hlo:all_passes",
    "//xla/pjrt:mlir_to_hlo",
    "//xla/translate/hlo_to_mhlo:hlo_to_mlir_hlo",
    "//xla/client:xla_computation",
    "//xla/client/lib:lu_decomposition",
    "//xla/client/lib:math",
    "//xla/client/lib:qr",
    "//xla/client/lib:svd",
    "//xla/client/lib:self_adjoint_eig",
    "//xla/client/lib:sorting",
    "//xla/pjrt:interpreter_device",
    "//xla/pjrt:pjrt_client",
    "//xla/pjrt:pjrt_compiler",
    "//xla/pjrt:tfrt_cpu_pjrt_client",
    "//xla/pjrt:pjrt_c_api_client",
    "//xla/pjrt/distributed",
    "//xla/pjrt/gpu:se_gpu_pjrt_client",
    "//xla/pjrt/distributed:client",
    "//xla/pjrt/distributed:service",
    "@com_google_absl//absl/types:span",
    "@com_google_absl//absl/types:optional",
    "@com_google_absl//absl/base:log_severity",
    "@com_google_protobuf//:protobuf",
    "@llvm-project//llvm:Support",
    "@llvm-project//mlir:FuncDialect",
    "@llvm-project//mlir:IR",
    "@llvm-project//mlir:Parser",
    "@llvm-project//mlir:Pass",
    "@llvm-project//mlir:ReconcileUnrealizedCasts",
    "@llvm-project//mlir:SparseTensorDialect",
    "@tsl//tsl/platform:errors",
    "@tsl//tsl/platform:fingerprint",
    "@tsl//tsl/platform:ml_dtypes",
    "@tsl//tsl/platform:statusor",
    "@tsl//tsl/platform:env_impl",
    "@tsl//tsl/platform:tensor_float_32_utils",
    "@tsl//tsl/profiler/utils:time_utils_impl",
    "@tsl//tsl/profiler/backends/cpu:annotation_stack_impl",
    "@tsl//tsl/profiler/backends/cpu:traceme_recorder_impl",
    "@tsl//tsl/protobuf:protos_all_cc_impl",
    "@tsl//tsl/protobuf:dnn_proto_cc_impl",
    "@tsl//tsl/framework:allocator",
    "@tsl//tsl/framework:allocator_registry_impl",
    "//xla/tsl/util:determinism",
  ]
  # GRPC Dependencies (needed for PjRt distributed)
  + tsl_grpc_cc_dependencies()
  + if_cuda_or_rocm([
    "//xla/service:gpu_plugin",
  ])
  + if_cuda([
    "//xla/stream_executor:cuda_platform"
  ])
  + if_rocm([
    "//xla/stream_executor:rocm_platform"
  ]),
  copts = ["-fvisibility=default"],
  linkopts= select({
    "//xla/tsl:macos": [
        # We set the install_name, such that the library is looked up
        # in the RPATH at runtime, otherwise the install_name is an
        # arbitrary path within bazel workspace
        "-Wl,-install_name,@rpath/libxla_extension.so",
        # We set RPATH to the same dir as libxla_extension.so, so that
        # loading PjRt plugins in the same directory works out of the box
        "-Wl,-rpath,@loader_path/",
    ],
    "//conditions:default": [
        "-Wl,-soname,libxla_extension.so",
        "-Wl,-rpath='$$ORIGIN'",
    ],
  }),
  features = ["-use_header_modules"],
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
      # Remap ml_dtypes paths
      d="$${d/_virtual_includes\\/intn\\/ml_dtypes/ml_dtypes}"
      d="$${d/_virtual_includes\\/float8\\/ml_dtypes/ml_dtypes}"
      mkdir -p "$@/$${d}"
      cp "$${f}" "$@/$${d}/"
    done
    # Files in xla/mlir_hlo include sibling headers from mhlo, so we
    # need to mirror them in includes
    cp -r $@/xla/mlir_hlo/mhlo $@
    """,
  )

genrule(
  name = "libtpu_whl",
  outs = ["libtpu.whl"],
  cmd = """
    libtpu_version="0.1.dev20231102"
    libtpu_storage_path="https://storage.googleapis.com/cloud-tpu-tpuvm-artifacts/wheels/libtpu-nightly/libtpu_nightly-$${libtpu_version}-py3-none-any.whl"
    wget -O "$@" "$$libtpu_storage_path"
  """
)

genrule(
  name = "libtpu_so",
  srcs = [
    ":libtpu_whl"
  ],
  outs = ["libtpu.so"],
  cmd = """
    unzip -p "$(SRCS)" libtpu/libtpu.so > "$@"
  """
)

# This genrule remaps libxla_extension.so to lib/libxla_extension.so
genrule(
  name = "xla_extension_lib",
  srcs = [
    ":libxla_extension.so",
  ]
  + if_with_tpu_support([
    ":libtpu_so"
  ]),
  outs = ["lib"],
  cmd = """
    mkdir $@
    mv $(SRCS) $@
  """
)

# See https://github.com/bazelbuild/rules_pkg/issues/517#issuecomment-1492917994
genrule(
  name = "xla_extension",
  outs = ["xla_extension.tar.gz"],
  srcs = [
    ":xla_extension_lib",
    ":xla_extension_headers",
  ],
  cmd = """
    mkdir xla_extension
    cp -r $(SRCS) xla_extension
    tar czf "$@" xla_extension
  """
)
