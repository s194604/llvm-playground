//===-- TestMatchers.h ------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIBC_UTILS_FPUTIL_TEST_HELPERS_H
#define LLVM_LIBC_UTILS_FPUTIL_TEST_HELPERS_H

#include "FPBits.h"

#include "utils/UnitTest/Test.h"

namespace __llvm_libc {
namespace fputil {
namespace testing {

template <typename ValType>
cpp::EnableIfType<cpp::IsFloatingPointType<ValType>::Value, void>
describeValue(const char *label, ValType value,
              testutils::StreamWrapper &stream);

template <typename T, __llvm_libc::testing::TestCondition Condition>
class FPMatcher : public __llvm_libc::testing::Matcher<T> {
  static_assert(__llvm_libc::cpp::IsFloatingPointType<T>::Value,
                "FPMatcher can only be used with floating point values.");
  static_assert(Condition == __llvm_libc::testing::Cond_EQ ||
                    Condition == __llvm_libc::testing::Cond_NE,
                "Unsupported FPMathcer test condition.");

  T expected;
  T actual;

public:
  FPMatcher(T expectedValue) : expected(expectedValue) {}

  bool match(T actualValue) {
    actual = actualValue;
    fputil::FPBits<T> actualBits(actual), expectedBits(expected);
    if (Condition == __llvm_libc::testing::Cond_EQ)
      return (actualBits.isNaN() && expectedBits.isNaN()) ||
             (actualBits.uintval() == expectedBits.uintval());

    // If condition == Cond_NE.
    if (actualBits.isNaN())
      return !expectedBits.isNaN();
    return expectedBits.isNaN() ||
           (actualBits.uintval() != expectedBits.uintval());
  }

  void explainError(testutils::StreamWrapper &stream) override {
    describeValue("Expected floating point value: ", expected, stream);
    describeValue("  Actual floating point value: ", actual, stream);
  }
};

template <__llvm_libc::testing::TestCondition C, typename T>
FPMatcher<T, C> getMatcher(T expectedValue) {
  return FPMatcher<T, C>(expectedValue);
}

// TODO: Make the matcher match specific exceptions instead of just identifying
// that an exception was raised.
class FPExceptMatcher : public __llvm_libc::testing::Matcher<bool> {
  bool exceptionRaised;

public:
  class FunctionCaller {
  public:
    virtual ~FunctionCaller(){};
    virtual void call() = 0;
  };

  template <typename Func> static FunctionCaller *getFunctionCaller(Func func) {
    struct Callable : public FunctionCaller {
      Func f;
      explicit Callable(Func theFunc) : f(theFunc) {}
      void call() override { f(); }
    };

    return new Callable(func);
  }

  // Takes ownership of func.
  explicit FPExceptMatcher(FunctionCaller *func);

  bool match(bool unused) { return exceptionRaised; }

  void explainError(testutils::StreamWrapper &stream) override {
    stream << "A floating point exception should have been raised but it "
           << "wasn't\n";
  }
};

} // namespace testing
} // namespace fputil
} // namespace __llvm_libc

#define DECLARE_SPECIAL_CONSTANTS(T)                                           \
  using FPBits = __llvm_libc::fputil::FPBits<T>;                               \
  using UIntType = typename FPBits::UIntType;                                  \
  const T zero = T(FPBits::zero());                                            \
  const T negZero = T(FPBits::negZero());                                      \
  const T aNaN = T(FPBits::buildNaN(1));                                       \
  const T inf = T(FPBits::inf());                                              \
  const T negInf = T(FPBits::negInf());

#define EXPECT_FP_EQ(expected, actual)                                         \
  EXPECT_THAT(                                                                 \
      actual,                                                                  \
      __llvm_libc::fputil::testing::getMatcher<__llvm_libc::testing::Cond_EQ>( \
          expected))

#define ASSERT_FP_EQ(expected, actual)                                         \
  ASSERT_THAT(                                                                 \
      actual,                                                                  \
      __llvm_libc::fputil::testing::getMatcher<__llvm_libc::testing::Cond_EQ>( \
          expected))

#define EXPECT_FP_NE(expected, actual)                                         \
  EXPECT_THAT(                                                                 \
      actual,                                                                  \
      __llvm_libc::fputil::testing::getMatcher<__llvm_libc::testing::Cond_NE>( \
          expected))

#define ASSERT_FP_NE(expected, actual)                                         \
  ASSERT_THAT(                                                                 \
      actual,                                                                  \
      __llvm_libc::fputil::testing::getMatcher<__llvm_libc::testing::Cond_NE>( \
          expected))

#ifdef LLVM_LIBC_TEST_USE_FUCHSIA
#define ASSERT_RAISES_FP_EXCEPT(func) ASSERT_DEATH(func, WITH_SIGNAL(SIGFPE))
#else
#define ASSERT_RAISES_FP_EXCEPT(func)                                          \
  ASSERT_THAT(                                                                 \
      true,                                                                    \
      __llvm_libc::fputil::testing::FPExceptMatcher(                           \
          __llvm_libc::fputil::testing::FPExceptMatcher::getFunctionCaller(    \
              func)))
#endif // LLVM_LIBC_TEST_USE_FUCHSIA

#endif // LLVM_LIBC_UTILS_FPUTIL_TEST_HELPERS_H
