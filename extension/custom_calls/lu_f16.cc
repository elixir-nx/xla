#include "lu.h"

#include "Eigen/Core"

ffi::Error lu_cpu_custom_call_f16_impl(ffi::Buffer<ffi::F16> operand,
                                       ffi::ResultBuffer<ffi::U8> p,
                                       ffi::ResultBuffer<ffi::F16> l,
                                       ffi::ResultBuffer<ffi::F16> u) {
  return lu_cpu_custom_call_impl<Eigen::half, ffi::Buffer<ffi::F16>>(operand,
                                                                     p, l, u);
}

XLA_FFI_DEFINE_HANDLER_SYMBOL(lu_cpu_custom_call_f16,
                              lu_cpu_custom_call_f16_impl,
                              ffi::Ffi::Bind()
                                  .Arg<ffi::Buffer<ffi::F16>>()
                                  .Ret<ffi::Buffer<ffi::U8>>()
                                  .Ret<ffi::Buffer<ffi::F16>>()
                                  .Ret<ffi::Buffer<ffi::F16>>());

XLA_FFI_REGISTER_HANDLER(ffi::GetXlaFfiApi(), "lu_cpu_custom_call_f16", "Host",
                         lu_cpu_custom_call_f16);
