; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse2    | FileCheck %s --check-prefixes=SSE,SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse4.1  | FileCheck %s --check-prefixes=SSE,SSE41
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx     | FileCheck %s --check-prefixes=AVX1

define float @trunc_unsigned_f32(float %x) #0 {
; SSE2-LABEL: trunc_unsigned_f32:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttss2si %xmm0, %rax
; SSE2-NEXT:    movl %eax, %eax
; SSE2-NEXT:    xorps %xmm0, %xmm0
; SSE2-NEXT:    cvtsi2ss %rax, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_unsigned_f32:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundss $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_f32:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundss $11, %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptoui float %x to i32
  %r = uitofp i32 %i to float
  ret float %r
}

define double @trunc_unsigned_f64(double %x) #0 {
; SSE2-LABEL: trunc_unsigned_f64:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttsd2si %xmm0, %rax
; SSE2-NEXT:    movq %rax, %rcx
; SSE2-NEXT:    sarq $63, %rcx
; SSE2-NEXT:    subsd {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE2-NEXT:    cvttsd2si %xmm0, %rdx
; SSE2-NEXT:    andq %rcx, %rdx
; SSE2-NEXT:    orq %rax, %rdx
; SSE2-NEXT:    movq %rdx, %xmm1
; SSE2-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],mem[0],xmm1[1],mem[1]
; SSE2-NEXT:    subpd {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1
; SSE2-NEXT:    movapd %xmm1, %xmm0
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm0 = xmm0[1],xmm1[1]
; SSE2-NEXT:    addsd %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_unsigned_f64:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundsd $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_f64:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundsd $11, %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptoui double %x to i64
  %r = uitofp i64 %i to double
  ret double %r
}

define <4 x float> @trunc_unsigned_v4f32(<4 x float> %x) #0 {
; SSE2-LABEL: trunc_unsigned_v4f32:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttps2dq %xmm0, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    psrad $31, %xmm2
; SSE2-NEXT:    subps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE2-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE2-NEXT:    pand %xmm2, %xmm0
; SSE2-NEXT:    por %xmm1, %xmm0
; SSE2-NEXT:    movdqa {{.*#+}} xmm1 = [65535,65535,65535,65535]
; SSE2-NEXT:    pand %xmm0, %xmm1
; SSE2-NEXT:    por {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1
; SSE2-NEXT:    psrld $16, %xmm0
; SSE2-NEXT:    por {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE2-NEXT:    subps {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE2-NEXT:    addps %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_unsigned_v4f32:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundps $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_v4f32:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundps $11, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptoui <4 x float> %x to <4 x i32>
  %r = uitofp <4 x i32> %i to <4 x float>
  ret <4 x float> %r
}

define <2 x double> @trunc_unsigned_v2f64(<2 x double> %x) #0 {
; SSE2-LABEL: trunc_unsigned_v2f64:
; SSE2:       # %bb.0:
; SSE2-NEXT:    movsd {{.*#+}} xmm2 = mem[0],zero
; SSE2-NEXT:    movapd %xmm0, %xmm1
; SSE2-NEXT:    subsd %xmm2, %xmm1
; SSE2-NEXT:    cvttsd2si %xmm1, %rax
; SSE2-NEXT:    cvttsd2si %xmm0, %rcx
; SSE2-NEXT:    movq %rcx, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rax, %rdx
; SSE2-NEXT:    orq %rcx, %rdx
; SSE2-NEXT:    movq %rdx, %xmm1
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm0 = xmm0[1,1]
; SSE2-NEXT:    cvttsd2si %xmm0, %rax
; SSE2-NEXT:    subsd %xmm2, %xmm0
; SSE2-NEXT:    cvttsd2si %xmm0, %rcx
; SSE2-NEXT:    movq %rax, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rcx, %rdx
; SSE2-NEXT:    orq %rax, %rdx
; SSE2-NEXT:    movq %rdx, %xmm0
; SSE2-NEXT:    punpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm0[0]
; SSE2-NEXT:    movdqa {{.*#+}} xmm0 = [4294967295,4294967295]
; SSE2-NEXT:    pand %xmm1, %xmm0
; SSE2-NEXT:    por {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0
; SSE2-NEXT:    psrlq $32, %xmm1
; SSE2-NEXT:    por {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1
; SSE2-NEXT:    subpd {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm1
; SSE2-NEXT:    addpd %xmm0, %xmm1
; SSE2-NEXT:    movapd %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_unsigned_v2f64:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundpd $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_v2f64:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundpd $11, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptoui <2 x double> %x to <2 x i64>
  %r = uitofp <2 x i64> %i to <2 x double>
  ret <2 x double> %r
}

define <4 x double> @trunc_unsigned_v4f64(<4 x double> %x) #0 {
; SSE2-LABEL: trunc_unsigned_v4f64:
; SSE2:       # %bb.0:
; SSE2-NEXT:    movapd %xmm1, %xmm2
; SSE2-NEXT:    movsd {{.*#+}} xmm3 = mem[0],zero
; SSE2-NEXT:    subsd %xmm3, %xmm1
; SSE2-NEXT:    cvttsd2si %xmm1, %rax
; SSE2-NEXT:    cvttsd2si %xmm2, %rcx
; SSE2-NEXT:    movq %rcx, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rax, %rdx
; SSE2-NEXT:    orq %rcx, %rdx
; SSE2-NEXT:    movq %rdx, %xmm1
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm2 = xmm2[1,1]
; SSE2-NEXT:    cvttsd2si %xmm2, %rax
; SSE2-NEXT:    subsd %xmm3, %xmm2
; SSE2-NEXT:    cvttsd2si %xmm2, %rcx
; SSE2-NEXT:    movq %rax, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rcx, %rdx
; SSE2-NEXT:    orq %rax, %rdx
; SSE2-NEXT:    movq %rdx, %xmm2
; SSE2-NEXT:    punpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm2[0]
; SSE2-NEXT:    movapd %xmm0, %xmm2
; SSE2-NEXT:    subsd %xmm3, %xmm2
; SSE2-NEXT:    cvttsd2si %xmm2, %rax
; SSE2-NEXT:    cvttsd2si %xmm0, %rcx
; SSE2-NEXT:    movq %rcx, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rax, %rdx
; SSE2-NEXT:    orq %rcx, %rdx
; SSE2-NEXT:    movq %rdx, %xmm2
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm0 = xmm0[1,1]
; SSE2-NEXT:    cvttsd2si %xmm0, %rax
; SSE2-NEXT:    subsd %xmm3, %xmm0
; SSE2-NEXT:    cvttsd2si %xmm0, %rcx
; SSE2-NEXT:    movq %rax, %rdx
; SSE2-NEXT:    sarq $63, %rdx
; SSE2-NEXT:    andq %rcx, %rdx
; SSE2-NEXT:    orq %rax, %rdx
; SSE2-NEXT:    movq %rdx, %xmm0
; SSE2-NEXT:    punpcklqdq {{.*#+}} xmm2 = xmm2[0],xmm0[0]
; SSE2-NEXT:    movdqa {{.*#+}} xmm0 = [4294967295,4294967295]
; SSE2-NEXT:    movdqa %xmm2, %xmm3
; SSE2-NEXT:    pand %xmm0, %xmm3
; SSE2-NEXT:    movdqa {{.*#+}} xmm4 = [4841369599423283200,4841369599423283200]
; SSE2-NEXT:    por %xmm4, %xmm3
; SSE2-NEXT:    psrlq $32, %xmm2
; SSE2-NEXT:    movdqa {{.*#+}} xmm5 = [4985484787499139072,4985484787499139072]
; SSE2-NEXT:    por %xmm5, %xmm2
; SSE2-NEXT:    movapd {{.*#+}} xmm6 = [1.9342813118337666E+25,1.9342813118337666E+25]
; SSE2-NEXT:    subpd %xmm6, %xmm2
; SSE2-NEXT:    addpd %xmm3, %xmm2
; SSE2-NEXT:    pand %xmm1, %xmm0
; SSE2-NEXT:    por %xmm4, %xmm0
; SSE2-NEXT:    psrlq $32, %xmm1
; SSE2-NEXT:    por %xmm5, %xmm1
; SSE2-NEXT:    subpd %xmm6, %xmm1
; SSE2-NEXT:    addpd %xmm0, %xmm1
; SSE2-NEXT:    movapd %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_unsigned_v4f64:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundpd $11, %xmm0, %xmm0
; SSE41-NEXT:    roundpd $11, %xmm1, %xmm1
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_v4f64:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundpd $11, %ymm0, %ymm0
; AVX1-NEXT:    retq
  %i = fptoui <4 x double> %x to <4 x i64>
  %r = uitofp <4 x i64> %i to <4 x double>
  ret <4 x double> %r
}

define float @trunc_signed_f32_no_fast_math(float %x) {
; SSE-LABEL: trunc_signed_f32_no_fast_math:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2ps %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_f32_no_fast_math:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttps2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2ps %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi float %x to i32
  %r = sitofp i32 %i to float
  ret float %r
}

; Without -0.0, it is ok to use roundss if it is available.

define float @trunc_signed_f32_nsz(float %x) #0 {
; SSE2-LABEL: trunc_signed_f32_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE2-NEXT:    cvtdq2ps %xmm0, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed_f32_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundss $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_f32_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundss $11, %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi float %x to i32
  %r = sitofp i32 %i to float
  ret float %r
}

define double @trunc_signed32_f64_no_fast_math(double %x) {
; SSE-LABEL: trunc_signed32_f64_no_fast_math:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttpd2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2pd %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_signed32_f64_no_fast_math:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttpd2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2pd %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i32
  %r = sitofp i32 %i to double
  ret double %r
}

define double @trunc_signed32_f64_nsz(double %x) #0 {
; SSE2-LABEL: trunc_signed32_f64_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttpd2dq %xmm0, %xmm0
; SSE2-NEXT:    cvtdq2pd %xmm0, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed32_f64_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundsd $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed32_f64_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundsd $11, %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i32
  %r = sitofp i32 %i to double
  ret double %r
}

define double @trunc_f32_signed32_f64_no_fast_math(float %x) {
; SSE-LABEL: trunc_f32_signed32_f64_no_fast_math:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2pd %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_f32_signed32_f64_no_fast_math:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttps2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2pd %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi float %x to i32
  %r = sitofp i32 %i to double
  ret double %r
}

define double @trunc_f32_signed32_f64_nsz(float %x) #0 {
; SSE-LABEL: trunc_f32_signed32_f64_nsz:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2pd %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_f32_signed32_f64_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttps2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2pd %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi float %x to i32
  %r = sitofp i32 %i to double
  ret double %r
}

define float @trunc_f64_signed32_f32_no_fast_math(double %x) {
; SSE-LABEL: trunc_f64_signed32_f32_no_fast_math:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttpd2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2ps %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_f64_signed32_f32_no_fast_math:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttpd2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2ps %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i32
  %r = sitofp i32 %i to float
  ret float %r
}

define float @trunc_f64_signed32_f32_nsz(double %x) #0 {
; SSE-LABEL: trunc_f64_signed32_f32_nsz:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttpd2dq %xmm0, %xmm0
; SSE-NEXT:    cvtdq2ps %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_f64_signed32_f32_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttpd2dq %xmm0, %xmm0
; AVX1-NEXT:    vcvtdq2ps %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i32
  %r = sitofp i32 %i to float
  ret float %r
}

define double @trunc_signed_f64_no_fast_math(double %x) {
; SSE-LABEL: trunc_signed_f64_no_fast_math:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttsd2si %xmm0, %rax
; SSE-NEXT:    xorps %xmm0, %xmm0
; SSE-NEXT:    cvtsi2sd %rax, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_f64_no_fast_math:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttsd2si %xmm0, %rax
; AVX1-NEXT:    vcvtsi2sd %rax, %xmm1, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i64
  %r = sitofp i64 %i to double
  ret double %r
}

define double @trunc_signed_f64_nsz(double %x) #0 {
; SSE2-LABEL: trunc_signed_f64_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttsd2si %xmm0, %rax
; SSE2-NEXT:    xorps %xmm0, %xmm0
; SSE2-NEXT:    cvtsi2sd %rax, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed_f64_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundsd $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_f64_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundsd $11, %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i64
  %r = sitofp i64 %i to double
  ret double %r
}

define <4 x float> @trunc_signed_v4f32_nsz(<4 x float> %x) #0 {
; SSE2-LABEL: trunc_signed_v4f32_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttps2dq %xmm0, %xmm0
; SSE2-NEXT:    cvtdq2ps %xmm0, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed_v4f32_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundps $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_v4f32_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundps $11, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi <4 x float> %x to <4 x i32>
  %r = sitofp <4 x i32> %i to <4 x float>
  ret <4 x float> %r
}

define <2 x double> @trunc_signed_v2f64_nsz(<2 x double> %x) #0 {
; SSE2-LABEL: trunc_signed_v2f64_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttsd2si %xmm0, %rax
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm0 = xmm0[1,1]
; SSE2-NEXT:    cvttsd2si %xmm0, %rcx
; SSE2-NEXT:    xorps %xmm0, %xmm0
; SSE2-NEXT:    cvtsi2sd %rax, %xmm0
; SSE2-NEXT:    cvtsi2sd %rcx, %xmm1
; SSE2-NEXT:    unpcklpd {{.*#+}} xmm0 = xmm0[0],xmm1[0]
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed_v2f64_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundpd $11, %xmm0, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_v2f64_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundpd $11, %xmm0, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi <2 x double> %x to <2 x i64>
  %r = sitofp <2 x i64> %i to <2 x double>
  ret <2 x double> %r
}

define <4 x double> @trunc_signed_v4f64_nsz(<4 x double> %x) #0 {
; SSE2-LABEL: trunc_signed_v4f64_nsz:
; SSE2:       # %bb.0:
; SSE2-NEXT:    cvttsd2si %xmm1, %rax
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm1 = xmm1[1,1]
; SSE2-NEXT:    cvttsd2si %xmm1, %rcx
; SSE2-NEXT:    cvttsd2si %xmm0, %rdx
; SSE2-NEXT:    unpckhpd {{.*#+}} xmm0 = xmm0[1,1]
; SSE2-NEXT:    cvttsd2si %xmm0, %rsi
; SSE2-NEXT:    xorps %xmm0, %xmm0
; SSE2-NEXT:    cvtsi2sd %rdx, %xmm0
; SSE2-NEXT:    xorps %xmm1, %xmm1
; SSE2-NEXT:    cvtsi2sd %rsi, %xmm1
; SSE2-NEXT:    unpcklpd {{.*#+}} xmm0 = xmm0[0],xmm1[0]
; SSE2-NEXT:    xorps %xmm1, %xmm1
; SSE2-NEXT:    cvtsi2sd %rax, %xmm1
; SSE2-NEXT:    cvtsi2sd %rcx, %xmm2
; SSE2-NEXT:    unpcklpd {{.*#+}} xmm1 = xmm1[0],xmm2[0]
; SSE2-NEXT:    retq
;
; SSE41-LABEL: trunc_signed_v4f64_nsz:
; SSE41:       # %bb.0:
; SSE41-NEXT:    roundpd $11, %xmm0, %xmm0
; SSE41-NEXT:    roundpd $11, %xmm1, %xmm1
; SSE41-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_v4f64_nsz:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vroundpd $11, %ymm0, %ymm0
; AVX1-NEXT:    retq
  %i = fptosi <4 x double> %x to <4 x i64>
  %r = sitofp <4 x i64> %i to <4 x double>
  ret <4 x double> %r
}

; The fold may be guarded to allow existing code to continue
; working based on its assumptions of float->int overflow.

define float @trunc_unsigned_f32_disable_via_attr(float %x) #1 {
; SSE-LABEL: trunc_unsigned_f32_disable_via_attr:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttss2si %xmm0, %rax
; SSE-NEXT:    movl %eax, %eax
; SSE-NEXT:    xorps %xmm0, %xmm0
; SSE-NEXT:    cvtsi2ss %rax, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_unsigned_f32_disable_via_attr:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttss2si %xmm0, %rax
; AVX1-NEXT:    movl %eax, %eax
; AVX1-NEXT:    vcvtsi2ss %rax, %xmm1, %xmm0
; AVX1-NEXT:    retq
  %i = fptoui float %x to i32
  %r = uitofp i32 %i to float
  ret float %r
}

define double @trunc_signed_f64_disable_via_attr(double %x) #1 {
; SSE-LABEL: trunc_signed_f64_disable_via_attr:
; SSE:       # %bb.0:
; SSE-NEXT:    cvttsd2si %xmm0, %rax
; SSE-NEXT:    xorps %xmm0, %xmm0
; SSE-NEXT:    cvtsi2sd %rax, %xmm0
; SSE-NEXT:    retq
;
; AVX1-LABEL: trunc_signed_f64_disable_via_attr:
; AVX1:       # %bb.0:
; AVX1-NEXT:    vcvttsd2si %xmm0, %rax
; AVX1-NEXT:    vcvtsi2sd %rax, %xmm1, %xmm0
; AVX1-NEXT:    retq
  %i = fptosi double %x to i64
  %r = sitofp i64 %i to double
  ret double %r
}

attributes #0 = { nounwind "no-signed-zeros-fp-math"="true" }
attributes #1 = { nounwind "no-signed-zeros-fp-math"="true" "strict-float-cast-overflow"="false" }
