// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// IRDL definition of the custom `pirtm` dialect: state-vector quantum ops and
// content-addressed hashing. Load with: mlir-opt --irdl-file=mlir/dialects/pirtm.irdl.mlir
// Each op lowers to a func.call of the function named in its comment
// (mlir/lib/*.mlir); the lowering is the `lowerCustom` table in lakefile.lean.
// Note: in IRDL one constraint variable binds one type, so operands that may
// differ in type use separate variables.

irdl.dialect @pirtm {
  // basis(nq, k) -> |k> on nq qubits                       => @sv_basis
  irdl.operation @basis {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%i, %i)
    irdl.results(%s)
  }
  // copy(state) -> state                                    => @sv_copy
  irdl.operation @copy {
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s)
    irdl.results(%s)
  }
  // single-qubit gates (state, nq, target) -> state         => @sv_h @sv_x @sv_y @sv_z @sv_s @sv_sdg
  irdl.operation @h {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  irdl.operation @x {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  irdl.operation @y {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  irdl.operation @z {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  irdl.operation @s {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  irdl.operation @sdg {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i)
    irdl.results(%s)
  }
  // cnot(state, nq, control, target) -> state               => @sv_cnot
  irdl.operation @cnot {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %i, %i)
    irdl.results(%s)
  }
  // circuit(n) -> n x 3 gate table                          => @circ_new
  irdl.operation @circuit {
    %i = irdl.is index
    %c = irdl.base "!builtin.memref"
    irdl.operands(%i)
    irdl.results(%c)
  }
  // gate(circ, row, opcode, q0, q1)                         => @set_gate
  irdl.operation @gate {
    %i = irdl.is index
    %c = irdl.base "!builtin.memref"
    irdl.operands(%c, %i, %i, %i, %i)
    irdl.results()
  }
  // evolve / evolve_inverse(state, nq, circ) -> state       => @sv_evolve @sv_evolve_inverse
  irdl.operation @evolve {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    %c = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %c)
    irdl.results(%s)
  }
  irdl.operation @evolve_inverse {
    %i = irdl.is index
    %s = irdl.base "!builtin.memref"
    %c = irdl.base "!builtin.memref"
    irdl.operands(%s, %i, %c)
    irdl.results(%s)
  }
  // fidelity(a, b) = |<a|b>|^2                              => @sv_fidelity
  irdl.operation @fidelity {
    %s = irdl.base "!builtin.memref"
    %f = irdl.is f64
    irdl.operands(%s, %s)
    irdl.results(%f)
  }
  // norm2(state)                                            => @sv_norm2
  irdl.operation @norm2 {
    %s = irdl.base "!builtin.memref"
    %f = irdl.is f64
    irdl.operands(%s)
    irdl.results(%f)
  }
  // sha256(bytes, len, out<8xi32>)                          => @sha256
  irdl.operation @sha256 {
    %m = irdl.base "!builtin.memref"
    %i = irdl.is index
    %d = irdl.base "!builtin.memref"
    irdl.operands(%m, %i, %d)
    irdl.results()
  }
}
