//===-- PatmosInstPrinter.h - Convert Patmos MCInst to assembly syntax ----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints a Patmos MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#ifndef _PATMOS_INSTPRINTER_H_
#define _PATMOS_INSTPRINTER_H_

#include "MCTargetDesc/PatmosMCAsmInfo.h"
#include "llvm/MC/MCInstPrinter.h"

namespace llvm {
  class MCOperand;

  class PatmosInstPrinter : public MCInstPrinter {
    PrintBytesLevel PrintBytes;

    bool InBundle;

  public:
    PatmosInstPrinter(const MCAsmInfo &mai, const MCInstrInfo &mii,
	                    const MCRegisterInfo &mri)
        : MCInstPrinter(mai, mii, mri), InBundle(false)
    {
      switch (mai.getAssemblerDialect()) {
      case 0: PrintBytes = PrintAsEncoded; break;
      case 1: PrintBytes = PrintCallAsBytes; break;
      case 2: PrintBytes = PrintAllAsBytes; break;
      }
    }

    void printInst(const MCInst *MI, uint64_t Address, StringRef Annot,
                   const MCSubtargetInfo &STI, raw_ostream &O) override;

    void printInstPrefix(const MCInst *MI, raw_ostream &O);

    void printOperand(const MCInst *MI, unsigned OpNo,
                      raw_ostream &O, const char *Modifier = 0);
    void printPredicateOperand(const MCInst *MI, unsigned OpNo,
                               raw_ostream &O, const char *Modifier = 0);
    void printPCRelTargetOperand(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &O);

    void printRegisterName(unsigned RegNo, raw_ostream &O);

    void printDefaultGuard(raw_ostream &O, bool NoGuard);

    // Autogenerated by tblgen.
    void printInstruction(const MCInst *MI, uint64_t Address, raw_ostream &O);

    static const char *getRegisterName(unsigned RegNo);

  private:
    bool isBundled(const MCInst *MI) const;
  };
}

#endif // _PATMOS_INSTPRINTER_H_
