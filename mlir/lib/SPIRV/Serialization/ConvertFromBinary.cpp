//===- ConvertFromBinary.cpp - MLIR SPIR-V binary to module conversion ----===//
//
// Copyright 2019 The MLIR Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================
//
// This file implements a translation from SPIR-V binary module to MLIR SPIR-V
// ModuleOp.
//
//===----------------------------------------------------------------------===//

#include "mlir/IR/Builders.h"
#include "mlir/IR/Module.h"
#include "mlir/SPIRV/SPIRVOps.h"
#include "mlir/SPIRV/Serialization.h"
#include "mlir/StandardOps/Ops.h"
#include "mlir/Support/FileUtilities.h"
#include "mlir/Translation.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/MemoryBuffer.h"

using namespace mlir;

// Adds a one-block function named as `spirv_module` to `module` and returns the
// block. The created block will be terminated by `std.return`.
Block *createOneBlockFunction(Builder builder, Module *module) {
  auto fnType = builder.getFunctionType(/*inputs=*/{}, /*results=*/{});
  auto *fn = new Function(builder.getUnknownLoc(), "spirv_module", fnType);
  module->getFunctions().push_back(fn);

  auto *block = new Block();
  fn->push_back(block);

  OperationState state(builder.getContext(), builder.getUnknownLoc(),
                       ReturnOp::getOperationName());
  ReturnOp::build(&builder, &state);
  block->push_back(Operation::create(state));

  return block;
}

// Deserializes the SPIR-V binary module stored in the file named as
// `inputFilename` and returns a module containing the SPIR-V module.
std::unique_ptr<Module> deserializeModule(llvm::StringRef inputFilename,
                                          MLIRContext *context) {
  Builder builder(context);

  std::string errorMessage;
  auto file = openInputFile(inputFilename, &errorMessage);
  if (!file) {
    context->emitError(builder.getUnknownLoc()) << errorMessage;
    return {};
  }

  // Make sure the input stream can be treated as a stream of SPIR-V words
  auto start = file->getBufferStart();
  auto end = file->getBufferEnd();
  if ((start - end) % sizeof(uint32_t) != 0) {
    context->emitError(builder.getUnknownLoc())
        << "SPIR-V binary module must contain integral number of 32-bit words";
    return {};
  }

  auto binary = llvm::makeArrayRef(reinterpret_cast<const uint32_t *>(start),
                                   (end - start) / sizeof(uint32_t));

  auto spirvModule = spirv::deserialize(binary, context);
  if (!spirvModule)
    return {};

  // TODO(antiagainst): due to the restriction of the current translation
  // infrastructure, we must return a MLIR module here. So we are wrapping the
  // converted SPIR-V ModuleOp inside a MLIR module. This should be changed to
  // return the SPIR-V ModuleOp directly after module and function are migrated
  // to be general ops.
  std::unique_ptr<Module> module(builder.createModule());
  Block *block = createOneBlockFunction(builder, module.get());
  block->push_front(spirvModule->getOperation());

  return module;
}

static TranslateToMLIRRegistration
    registration("deserialize-spirv",
                 [](StringRef inputFilename, MLIRContext *context) {
                   return deserializeModule(inputFilename, context);
                 });
