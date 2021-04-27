//===-- PatmosAsmPrinter.cpp - Patmos LLVM assembly writer ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is here from the legacy asm printing infrastructure and
// probably will vanish one day.
//
//===----------------------------------------------------------------------===//

#include "PatmosAsmPrinter.h"
#include "PatmosMCInstLower.h"
#include "PatmosMachineFunctionInfo.h"
#include "PatmosTargetMachine.h"
#include "TargetInfo/PatmosTargetInfo.h"
#include "InstPrinter/PatmosInstPrinter.h"
#include "MCTargetDesc/PatmosTargetStreamer.h"
#include "TargetInfo/PatmosTargetInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCContext.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

/// EnableBasicBlockSymbols - If enabled, symbols for basic blocks are emitted
/// containing the name of their IR representation, appended by their
/// MBB number (for uniqueness). Note that this also includes MBBs which are
/// not necessarily branch/call targets.
static cl::opt<bool> EnableBasicBlockSymbols(
  "mpatmos-enable-bb-symbols",
  cl::init(false),
  cl::desc("Enable (additional) generation of symbols "
           "named like the IR basic blocks."),
  cl::Hidden);



void PatmosAsmPrinter::emitFunctionEntryLabel() {
  // Create a temp label that will be emitted at the end of the first cache block (at the end of the function
  // if the function has only one cache block)
  CurrCodeEnd = OutContext.createTempSymbol();

  // emit a function/subfunction start directive
  EmitFStart(CurrentFnSymForSize, CurrCodeEnd, FStartAlignment);

  // Now emit the normal function label
  AsmPrinter::emitFunctionEntryLabel();
}

void PatmosAsmPrinter::emitBasicBlockStart(const MachineBasicBlock &MBB) {

  // First align the block if needed (don't align the first block).
  // We must align first to ensure that any added nops are put
  // before the .fstart, such that when object code is emitted
  // the .size is put right before the label of the block with no nops
  // between.
  auto align = MBB.getAlignment();
  if (align.value() && (MBB.getParent()->getBlockNumbered(0) != &MBB)) {
      emitAlignment(Align(align));
  }

  // Then emit .fstart/.size if needed
  if (isFStart(&MBB) && (MBB.getParent()->getBlockNumbered(0) != &MBB)) {
    // We need an address symbol from the next block
    assert(!MBB.pred_empty() && "Basic block without predecessors do not emit labels, unsupported.");

    MCSymbol *SymStart = MBB.getSymbol();

    // create new end symbol
    CurrCodeEnd = OutContext.createTempSymbol();

    // mark subfunction labels as function labels
    OutStreamer->emitSymbolAttribute(SymStart, MCSA_ELF_TypeFunction);

    // emit a .size directive
    emitDotSize(SymStart, CurrCodeEnd);

    // emit a function/subfunction start directive
    EmitFStart(SymStart, CurrCodeEnd, FStartAlignment);
  }

  // We remove any alignment assigned to the block, to ensure
  // AsmPrinter::EmitBasicBlockStart doesn't also try to align the block
  ((MachineBasicBlock &) MBB).setAlignment(Align(1));
  AsmPrinter::emitBasicBlockStart(MBB);
  ((MachineBasicBlock &) MBB).setAlignment(Align(align));
}

void PatmosAsmPrinter::emitBasicBlockBegin(const MachineBasicBlock &MBB) {
  // If special generation of BB symbols is enabled,
  // do so for every MBB.
  if (EnableBasicBlockSymbols) {
    // create a symbol with the BBs name
    SmallString<128> bbname;
    getMBBIRName(&MBB, bbname);
    MCSymbol *bbsym = OutContext.getOrCreateSymbol(bbname.str());
    OutStreamer->emitLabel(bbsym);

    // set basic block size
    unsigned int bbsize = 0;
    for(MachineBasicBlock::const_instr_iterator i(MBB.instr_begin()),
        ie(MBB.instr_end()); i!=ie; ++i)
    {
      bbsize += i->getDesc().Size;
    }
    OutStreamer->emitELFSize(bbsym, MCConstantExpr::create(bbsize, OutContext));
  }

  // Print loop bound information if needed
  auto loop_bounds = getLoopBounds(&MBB);
  if (loop_bounds.first > -1 || loop_bounds.second > -1){
    OutStreamer->GetCommentOS() << "Loop bound: [";
    if (loop_bounds.first > -1){
      OutStreamer->GetCommentOS() << loop_bounds.first;
    } else {
      OutStreamer->GetCommentOS() << "-";
    }
    OutStreamer->GetCommentOS() << ", ";
    if (loop_bounds.second > -1){
      OutStreamer->GetCommentOS() << loop_bounds.second;
    } else {
      OutStreamer->GetCommentOS() << "-";
    }
    OutStreamer->GetCommentOS() << "]\n";
    OutStreamer->AddBlankLine();
  }

}


void PatmosAsmPrinter::emitBasicBlockEnd(const MachineBasicBlock &MBB) {

  // EmitBasicBlockBegin emits after the label, too late for emitting .fstart,
  // so we do it at the end of the previous block of a cache block start MBB.
  if (&MBB.getParent()->back() == &MBB) return;
  const MachineBasicBlock *Next = MBB.getNextNode();

  bool followedByFStart = isFStart(Next);

  if (followedByFStart) {
    // Next is the start of a new cache block, close the old one before the
    // alignment of the next block
    OutStreamer->emitLabel(CurrCodeEnd);
  }
}

void PatmosAsmPrinter::emitFunctionBodyEnd() {
  // Emit the end symbol of the last cache block
  OutStreamer->emitLabel(CurrCodeEnd);
}

void PatmosAsmPrinter::emitDotSize(MCSymbol *SymStart, MCSymbol *SymEnd) {
  const MCExpr *SizeExpr =
    MCBinaryExpr::createSub(MCSymbolRefExpr::create(SymEnd,   OutContext),
                            MCSymbolRefExpr::create(SymStart, OutContext),
                            OutContext);

  OutStreamer->emitELFSize(SymStart, SizeExpr);
}

void PatmosAsmPrinter::EmitFStart(MCSymbol *SymStart, MCSymbol *SymEnd,
                                     unsigned Alignment) {
  // convert LLVM's log2-block alignment to bytes
  unsigned AlignBytes = std::max(4u, 1u << Alignment);

  // emit .fstart SymStart, SymEnd-SymStart
  const MCExpr *SizeExpr =
    MCBinaryExpr::createSub(MCSymbolRefExpr::create(SymEnd,   OutContext),
                            MCSymbolRefExpr::create(SymStart, OutContext),
                            OutContext);

  PatmosTargetStreamer *PTS =
            static_cast<PatmosTargetStreamer*>(OutStreamer->getTargetStreamer());

  PTS->EmitFStart(SymStart, SizeExpr, AlignBytes);
}

bool PatmosAsmPrinter::isFStart(const MachineBasicBlock *MBB) const {
  // query the machineinfo object - the PatmosFunctionSplitter, or some other
  // pass, has marked all entry blocks already.
  const PatmosMachineFunctionInfo *PMFI =
                                       MF->getInfo<PatmosMachineFunctionInfo>();
  return PMFI->isMethodCacheRegionEntry(MBB);
}


void PatmosAsmPrinter::emitInstruction(const MachineInstr *MI) {

  SmallVector<const MachineInstr*, 2> BundleMIs;
  unsigned Size = 1;

  // Unpack BUNDLE instructions
  if (MI->isBundle()) {

    const MachineBasicBlock *MBB = MI->getParent();
    auto MII = MI;
    ++MII;
    while (MII != MBB->end() && MII->isInsideBundle()) {
      const MachineInstr *MInst = MII;
      if (MInst->isPseudo()) {
        // DBG_VALUE and IMPLICIT_DEFs outside of bundles are handled in
        // AsmPrinter::EmitFunctionBody()
        MInst->dump();
        report_fatal_error("Pseudo instructions must not be bundled!");
      }

      BundleMIs.push_back(MInst);
      ++MII;
    }
    Size = BundleMIs.size();
    assert(Size == MI->getBundleSize() && "Corrupt Bundle!");
  }
  else {
    BundleMIs.push_back(MI);
  }

  // Emit all instructions in the bundle.
  for (unsigned Index = 0; Index < Size; Index++) {
    MCInst MCI;
    MCInstLowering.Lower(BundleMIs[Index], MCI);

    // Set bundle marker
    bool isBundled = (Index < Size - 1);
    MCI.addOperand(MCOperand::createImm(isBundled));

    OutStreamer->emitInstruction(MCI, *TM.getMCSubtargetInfo());
  }
}


bool PatmosAsmPrinter::
isBlockOnlyReachableByFallthrough(const MachineBasicBlock *MBB) const {
  // If this is a landing pad, it isn't a fall through.  If it has no preds,
  // then nothing falls through to it.
  if (MBB->isEHPad() || MBB->pred_empty() || MBB->hasAddressTaken())
    return false;

  // If there isn't exactly one predecessor, it can't be a fall through.
  MachineBasicBlock::const_pred_iterator PI = MBB->pred_begin(), PI2 = PI;
  if (++PI2 != MBB->pred_end())
    return false;

  // The predecessor has to be immediately before this block.
  const MachineBasicBlock *Pred = *PI;

  if (!Pred->isLayoutSuccessor(MBB))
    return false;

  // if the block starts a new cache block, do not fall through (we need to
  // insert cache stuff, even if we only reach this block from a jump from the
  // previous block, and we need the label).
  if (isFStart(MBB))
    return false;

  // If the block is completely empty, then it definitely does fall through.
  if (Pred->empty())
    return true;


  // Here is the difference to the AsmPrinter method;
  // We do not check properties of all terminator instructions
  // (delay slot instructions do not have to be terminators),
  // but instead check if the *last terminator* is an
  // unconditional branch (no barrier)
  MachineBasicBlock::const_iterator I = Pred->end();
  // find last terminator
  while (I != Pred->begin() && !(--I)->isTerminator()) ;
  return I == Pred->end() || !I->isBarrier();
}


bool PatmosAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                       const char *ExtraCode, raw_ostream &OS)

{
  // Does this asm operand have a single letter operand modifier?
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  // Print operand for inline-assembler. Basically the same code as in
  // PatmosInstPrinter::printOperand, but for MachineOperand and for
  // inline-assembly. No need for pretty formatting of default ops, output is
  // for AsmParser only.

  // TODO any special handling of predicates (flags) or anything?

  MCInst MCI;
  MCInstLowering.Lower(MI, MCI);

  PatmosInstPrinter PIP(*OutContext.getAsmInfo(), *TM.getMCInstrInfo(),
                        *TM.getMCRegisterInfo());

  PIP.printOperand(&MCI, OpNo, OS, ExtraCode);

  return false;
}

bool PatmosAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                                             const char *ExtraCode, raw_ostream &OS)
{
  if (ExtraCode && ExtraCode[0])
     return true; // Unknown modifier.

  const MachineOperand &MO = MI->getOperand(OpNo);
  assert(MO.isReg() && "unexpected inline asm memory operand");
  OS << "[$" << PatmosInstPrinter::getRegisterName(MO.getReg()) << "]";
  return false;
}



////////////////////////////////////////////////////////////////////////////////

// Force static initialization.
extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializePatmosAsmPrinter() {
  RegisterAsmPrinter<PatmosAsmPrinter> X(getThePatmosTarget());
}
