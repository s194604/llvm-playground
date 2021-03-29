//====-- PatmosSubtarget.h - Define Subtarget for the Patmos ---*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Patmos specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef _LLVM_TARGET_PATMOS_SUBTARGET_H_
#define _LLVM_TARGET_PATMOS_SUBTARGET_H_

#include "PatmosInstrInfo.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"

#define GET_SUBTARGETINFO_HEADER
#include "PatmosGenSubtargetInfo.inc"

#include <string>

namespace llvm {
class StringRef;

class PatmosSubtarget : public PatmosGenSubtargetInfo {
  bool HasFPU;
  bool HasMethodCache;

  InstrItineraryData InstrItins;

public:
  /// This constructor initializes the data members to match that
  /// of the specified triple.
  ///
  PatmosSubtarget(const std::string &TT, const std::string &CPU,
                  const std::string &FS);

  /// ParseSubtargetFeatures - Parses features string setting specified
  /// subtarget options.  Definition of function is auto generated by tblgen.
  void ParseSubtargetFeatures(StringRef CPU, StringRef FS);

  /// getInstrItins - Return the instruction itineraries based on subtarget.
  const InstrItineraryData &getInstrItineraryData() const { return InstrItins; }

  bool hasFPU() const { return HasFPU; }

  bool hasMethodCache() const { return HasMethodCache; }

  virtual bool enablePostRAScheduler(CodeGenOpt::Level OptLevel,
                                    TargetSubtargetInfo::AntiDepBreakMode& Mode,
                                    RegClassVector& CriticalPathRCs) const;

  /// return true if bundles should be emitted.
  bool enableBundling(CodeGenOpt::Level OptLevel) const;

  /// return true if any Post-RA scheduler should be used.
  bool hasPostRAScheduler(CodeGenOpt::Level OptLevel) const;

  /// Return true if the MI Pre-RA Scheduler should be used.
  bool usePreRAMIScheduler(CodeGenOpt::Level OptLevel) const;

  /// Return true if the Patmos scheduler should be used instead of the default
  /// post-RA scheduler.
  bool usePatmosPostRAScheduler(CodeGenOpt::Level OptLevel) const;

  typedef enum { CFL_DELAYED, CFL_MIXED, CFL_NON_DELAYED } CFLType;

  // Return the type of control-flow instructions to be generated
  CFLType getCFLType() const;

  /////////////////////////////////////////////////////////////////////////////
  // Patmos specific architecture parameters (cache sizes, types, features,..)

  /// Return the number of delay slot cycles of control flow instructions
  /// \param LocalBranch if true, return the cycles for a local branch,
  ///              otherwise return the cycles for instructions with cache fill.
  unsigned getCFLDelaySlotCycles(bool LocalBranch) const {
    return LocalBranch ? 2 : 3;
  }

  /// Return the number of delay slot cycles of control flow instructions
  unsigned getDelaySlotCycles(const MachineInstr &MI) const;

  /// Get the maximum number of bytes an instruction can have in the delay slots
  /// (excluding the second slot of this instruction)
  unsigned getMaxDelaySlotCodeSize(const MachineInstr *MI) const {
    return getDelaySlotCycles(MI) * 8;
  }

  /// Return true if branches might be scheduled inside delay slots of CFL
  /// instructions.
  bool allowBranchInsideCFLDelaySots() const;

  /// Return the latency of MUL instructions
  unsigned getMULLatency() const { return 1; }

  /// Get the width of an instruction.
  unsigned getIssueWidth(unsigned SchedClass) const;

  /// Check if a given schedule class can be issued in a given slot.
  /// @see PatmosInstrInfo::canIssueInSlot
  bool canIssueInSlot(unsigned SchedClass, unsigned Slot) const;

  /// Get the minimum (sub)function alignment in log2(bytes).
  unsigned getMinSubfunctionAlignment() const;

  /// Get the minimum basic block alignment in log2(bytes).
  unsigned getMinBasicBlockAlignment() const;

  unsigned getStackCacheSize() const;

  unsigned getStackCacheBlockSize() const;

  unsigned getMethodCacheSize() const;

  /// Return the actual size of a stack cache frame in bytes.
  /// @param frameSize the required frame size in bytes.
  unsigned getAlignedStackFrameSize(unsigned frameSize) const;

};
} // End llvm namespace

#endif  // _LLVM_TARGET_PATMOS_SUBTARGET_H_
