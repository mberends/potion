//
// p2.h
//
// (c) 2008 why the lucky stiff, the freelance professor
// (c) 2013 by perl11 org
//
#ifndef P2_H
#define P2_H

#define P2_VERSION  "0.0"
#define P2_MINOR    0
#define P2_MAJOR    0
#define P2_SIG      "p\02\10n"
#define P2_VMID     0x79

#include "potion.h"

#ifdef P2
#  undef NIL_NAME
#  define NIL_NAME "undef" // nil => undef
#endif

//
// additional p2 functions
//

PN p2_source_load(Potion *P, PN cl, PN buf);
PN p2_parse(Potion *, PN);
PN p2_run(Potion *, PN, int);
PN p2_eval(Potion *, PN, int);
// not yet:
//PN p2_vm_proto(Potion *, PN, PN, ...);
//PN p2_vm_class(Potion *, PN, PN);
//PN p2_vm(Potion *, PN, PN, PN, PN_SIZE, PN * volatile);
//PN_F p2_jit_proto(Potion *, PN, PN);

#ifdef P2
PN potion_any_is_defined(Potion *, PN, PN);

#define potion_load_code   p2_load_code
#define potion_load        p2_load
#define potion_source_load p2_source_load
#define potion_parse       p2_parse
#define potion_run         p2_run
#define potion_eval        p2_eval
//#define potion_vm_proto    p2_vm_proto
//#define potion_vm_class    p2_vm_class
//#define potion_vm          p2_vm
#endif

#endif
