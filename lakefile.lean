-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
import Lake
open Lake DSL System

package «pirtm-hcalc» where
  version := v!"1.0.0"

@[default_target] lean_lib PIRTM
@[default_target] lean_lib Hcalc
@[default_target] lean_lib PirtmHcalc

/-! # Driver

All build/run logic of the project lives in the Lake scripts below
(`lake script run <name>`): `j`, `mlir`, `irdl`, `quipper`, `lean`, `all`.
Tool locations can be overridden with the environment variables
`LLVM_BIN`, `MLIR_RUNNER_LIB`, `JCONSOLE`, `GHCUP_BIN`, `TINFO5_DIR`. -/

def envOr (k d : String) : IO String := return (← IO.getEnv k).getD d

def llvmBin : IO String := envOr "LLVM_BIN" "/usr/lib/llvm-19/bin"
def runnerLib : IO String := envOr "MLIR_RUNNER_LIB" "/usr/lib/llvm-19/lib/libmlir_c_runner_utils.so"
def jconsole : IO String := envOr "JCONSOLE" "/home/box/j/j9.7/bin/jconsole"

def proc (cmd : String) (args : Array String) (cwd : Option FilePath := none)
    (env : Array (String × Option String) := #[]) : IO IO.Process.Output := do
  try
    IO.Process.output { cmd, args, cwd, env }
  catch e =>
    return { exitCode := 127, stdout := "", stderr := s!"cannot start {cmd}: {e}" }

def stamp : IO String := do
  let o ← proc "date" #["+%Y-%m-%d %H:%M:%S %Z"]
  return o.stdout.trimRight

def writeLog (path : FilePath) (text : String) : IO Unit := do
  if let some d := path.parent then IO.FS.createDirAll d
  IO.FS.writeFile path text

def say (log : IO.Ref String) (s : String) : IO Unit := do
  IO.println s
  log.modify (· ++ s ++ "\n")

def linesOf (s : String) : List String :=
  let ls := s.splitOn "\n"
  if ls.getLast? == some "" then ls.dropLast else ls

/-- `mlir-cpu-runner` prints the i32 returned by `main` as its own line; drop it. -/
def dropRunnerResult (ls : List String) : List String :=
  match ls with
  | "0" :: rest => rest
  | _ => if ls.getLast? == some "0" then ls.dropLast else ls

/-- Lines of the section of `ls` whose header starts with `hdr`, header included,
up to the next `== ` header. -/
def sectionOf (ls : List String) (hdr : String) : List String :=
  match ls.dropWhile (fun l => !l.startsWith hdr) with
  | [] => []
  | h :: rest => h :: rest.takeWhile (fun l => !l.startsWith "== ")

def isSubseq : List String → List String → Bool
  | [], _ => true
  | _ :: _, [] => false
  | e :: es, g :: gs => if e == g then isSubseq es gs else isSubseq (e :: es) gs

def firstDiff (a b : List String) : String :=
  let rec go (i : Nat) : List String → List String → String
    | [], [] => "identical"
    | x :: _, [] => s!"line {i}: got '{x}', expected end of output"
    | [], y :: _ => s!"line {i}: output ended, expected '{y}'"
    | x :: xs, y :: ys => if x == y then go (i+1) xs ys else s!"line {i}: got '{x}', expected '{y}'"
  go 1 a b

def lowerFlags : Array String := #[
  "--convert-complex-to-standard", "--arith-expand", "--convert-math-to-llvm",
  "--convert-scf-to-cf", "--finalize-memref-to-llvm", "--convert-complex-to-llvm",
  "--convert-arith-to-llvm", "--convert-func-to-llvm", "--convert-cf-to-llvm",
  "--reconcile-unrealized-casts"]

/-- Lowering of the custom dialects: generic-form op `"d.op"(` becomes
`func.call @fn(`; operand/result types are unchanged, so the generic op's
trailing function type is exactly the func.call type. -/
def lowerCustom : List (String × String) := [
  ("pirtm.basis", "sv_basis"), ("pirtm.copy", "sv_copy"),
  ("pirtm.h", "sv_h"), ("pirtm.x", "sv_x"), ("pirtm.y", "sv_y"), ("pirtm.z", "sv_z"),
  ("pirtm.s", "sv_s"), ("pirtm.sdg", "sv_sdg"), ("pirtm.cnot", "sv_cnot"),
  ("pirtm.circuit", "circ_new"), ("pirtm.gate", "set_gate"),
  ("pirtm.evolve", "sv_evolve"), ("pirtm.evolve_inverse", "sv_evolve_inverse"),
  ("pirtm.fidelity", "sv_fidelity"), ("pirtm.norm2", "sv_norm2"), ("pirtm.sha256", "sha256"),
  ("hcalc.tp_alpha", "tp_alpha"), ("hcalc.tp", "tp_from_p64"), ("hcalc.c", "c_wrap"),
  ("hcalc.lambda_m", "lam_m"), ("hcalc.step", "hcalc_step"), ("hcalc.residual", "residual_linf"),
  ("hcalc.run", "hcalc_run"), ("hcalc.gl_add", "gl_add"), ("hcalc.gl_sub", "gl_sub"),
  ("hcalc.gl_mul", "gl_mul"), ("hcalc.gl_pow", "gl_pow"), ("hcalc.gl_inv", "gl_inv")]

def lowerText (s : String) : String :=
  lowerCustom.foldl (fun acc (op, fn) => acc.replace s!"\"{op}\"(" s!"func.call @{fn}(") s

def concatFiles (files : List String) : IO String := do
  let mut out := ""
  for f in files do
    out := out ++ (← IO.FS.readFile ("mlir" / f)) ++ "\n"
  return out

/-- Lower an MLIR module (text) to LLVM and run `main`; returns (exit, stdout lines, stderr). -/
def lowerAndRun (name src : String) : IO (UInt32 × List String × String) := do
  let bin ← llvmBin
  let dir : FilePath := ".lake" / "mlir"
  IO.FS.createDirAll dir
  let inp := dir / s!"{name}.in.mlir"
  let ll := dir / s!"{name}.ll.mlir"
  IO.FS.writeFile inp src
  let o ← proc s!"{bin}/mlir-opt" (#[inp.toString] ++ lowerFlags ++ #["-o", ll.toString])
  if o.exitCode != 0 then return (o.exitCode, [], o.stderr)
  let r ← proc s!"{bin}/mlir-cpu-runner"
    #[ll.toString, "-e", "main", "--entry-point-result=i32", s!"-shared-libs={← runnerLib}"]
  return (r.exitCode, dropRunnerResult (linesOf r.stdout), r.stderr)

inductive Check where
  | exact (expected : List String)
  | subseq (expected : List String)
  | linesIn (pool : List String)

def judge (got : List String) : Check → Bool × String
  | .exact e => (got == e, if got == e then s!"identical ({e.length} lines)" else firstDiff got e)
  | .subseq e => (isSubseq e got, if isSubseq e got then s!"all {e.length} reference lines present in order"
                   else "reference lines missing or out of order")
  | .linesIn p =>
    let missing := got.filter (fun l => !p.contains l)
    (missing.isEmpty && !got.isEmpty,
      if missing.isEmpty then s!"all {got.length} lines found in the reference"
      else s!"{missing.length} lines not in reference, first: '{missing.head!}'")

def readLines (p : FilePath) : IO (List String) := do
  if ← p.pathExists then return linesOf (← IO.FS.readFile p) else return []

def expectedDir : FilePath := "logs" / "reference" / "expected"

/-- (name, files under mlir/, check, what the check compares with) -/
def mainPrograms (jdemo : List String) : IO (List (String × List String × Check × String)) := do
  let e (f : String) := readLines (expectedDir / f)
  return [
    ("hilbert11", ["lib/io.mlir", "lib/qsim.mlir", "lib/qmat.mlir", "main/hilbert11.mlir"],
      .exact (← e "hilbert11.txt"), "Python PIRTM (expected/hilbert11.txt)"),
    ("quantum", ["lib/io.mlir", "lib/qsim.mlir", "lib/qmat.mlir", "main/quantum.mlir"],
      .exact (← e "quantum.txt"), "Python PIRTM (expected/quantum.txt)"),
    ("oracle", ["lib/io.mlir", "lib/sha256.mlir", "lib/oracle.mlir", "main/oracle.mlir"],
      .exact (← e "oracle.txt"), "Python PIRTM (expected/oracle.txt)"),
    ("engine", ["lib/io.mlir", "lib/sha256.mlir", "lib/oracle.mlir", "main/engine.mlir"],
      .subseq (← e "engine.subseq.txt"), "Python PIRTM (expected/engine.subseq.txt)"),
    ("agents", ["lib/io.mlir", "lib/sha256.mlir", "lib/oracle.mlir", "lib/qsim.mlir", "main/agents.mlir"],
      .exact (← e "agents.txt"), "Python PIRTM (expected/agents.txt)"),
    ("hcalc", ["lib/io.mlir", "lib/hcalc.mlir", "main/hcalc.mlir"],
      .exact (sectionOf jdemo "== hcalc"), "J (logs/j/demo.out, hcalc section)"),
    ("goldilocks", ["lib/io.mlir", "lib/goldilocks.mlir", "main/goldilocks.mlir"],
      .exact (sectionOf jdemo "== goldilocks"), "J (logs/j/demo.out, goldilocks section)")]

/-- (name, dialect, lib files, custom file, check, reference) -/
def customPrograms (jdemo : List String) : IO (List (String × String × List String × String × Check × String)) := do
  let h ← readLines (expectedDir / "hilbert11.txt")
  let o ← readLines (expectedDir / "oracle.txt")
  return [
    ("hcalc_pipeline", "hcalc", ["lib/io.mlir", "lib/jfmt.mlir", "lib/hcalc.mlir", "lib/goldilocks.mlir"],
      "custom/hcalc_pipeline.mlir", .linesIn jdemo, "J (logs/j/demo.out)"),
    ("pirtm_roundtrip", "pirtm", ["lib/io.mlir", "lib/sha256.mlir", "lib/qsim.mlir"],
      "custom/pirtm_roundtrip.mlir", .linesIn (h ++ o), "Python PIRTM (expected/hilbert11.txt + oracle.txt)")]

def runJ : IO UInt32 := do
  let log ← IO.mkRef ""
  let jc ← jconsole
  say log s!"== j  ({← stamp})"
  say log s!"jconsole: {jc}"
  let d ← proc jc #["j/demo.ijs"]
  writeLog ("logs" / "j" / "demo.out") d.stdout
  say log s!"jconsole j/demo.ijs -> exit {d.exitCode}, {(linesOf d.stdout).length} lines -> logs/j/demo.out"
  if !d.stderr.isEmpty then say log s!"stderr: {d.stderr}"
  let v ← proc jc #["verify/run.ijs"]
  writeLog ("logs" / "j" / "verify.out") v.stdout
  let summary := (linesOf v.stdout).filter (·.startsWith "PASS=")
  say log s!"jconsole verify/run.ijs -> exit {v.exitCode}; {summary} -> logs/j/verify.out"
  let ok := d.exitCode == 0 && v.exitCode == 0 && summary.any (fun l => (l.splitOn "FAIL=0").length > 1)
  say log s!"j: {if ok then "PASS" else "FAIL"}"
  writeLog ("logs" / "j" / "SUMMARY.txt") (← log.get)
  return if ok then 0 else 1

def runMlir : IO UInt32 := do
  let log ← IO.mkRef ""
  say log s!"== mlir  ({← stamp})"
  let jdemo ← readLines ("logs" / "j" / "demo.out")
  if jdemo.isEmpty then say log "note: logs/j/demo.out missing; run `lake script run j` first (hcalc/goldilocks checks will fail)"
  let mut fails := 0
  for (name, files, chk, ref) in ← mainPrograms jdemo do
    let (rc, out, err) ← lowerAndRun name (← concatFiles files)
    writeLog ("logs" / "mlir" / s!"{name}.out") (String.intercalate "\n" out ++ "\n")
    let (ok, why) := if rc == 0 then judge out chk else (false, s!"exit {rc}: {err.take 400}")
    if !ok then fails := fails + 1
    say log s!"{if ok then "PASS" else "FAIL"} main/{name}.mlir vs {ref}: {why}"
  let bin ← llvmBin
  for (name, dialect, libs, file, chk, ref) in ← customPrograms jdemo do
    let src := (← concatFiles libs) ++ (← IO.FS.readFile ("mlir" / file))
    let vf : FilePath := ".lake" / "mlir" / s!"{name}.custom.mlir"
    IO.FS.createDirAll (".lake" / "mlir")
    IO.FS.writeFile vf src
    let v ← proc s!"{bin}/mlir-opt" #[s!"--irdl-file=mlir/dialects/{dialect}.irdl.mlir", vf.toString, "-o", "/dev/null"]
    let lowered := lowerText src
    let left := (lowered.splitOn s!"\"{dialect}.").length - 1
    let (rc, out, err) ← lowerAndRun name lowered
    writeLog ("logs" / "mlir" / s!"{name}.out") (String.intercalate "\n" out ++ "\n")
    let (ok, why) :=
      if v.exitCode != 0 then (false, s!"IRDL verification failed: {v.stderr.take 400}")
      else if left != 0 then (false, s!"{left} custom ops left after lowering")
      else if rc != 0 then (false, s!"exit {rc}: {err.take 400}")
      else judge out chk
    if !ok then fails := fails + 1
    say log s!"{if ok then "PASS" else "FAIL"} {file} (IRDL-verified {dialect}, lowered to func.call) vs {ref}: {why}"
  say log s!"mlir: {if fails == 0 then "PASS" else s!"FAIL ({fails})"}"
  writeLog ("logs" / "mlir" / "SUMMARY.txt") (← log.get)
  return if fails == 0 then 0 else 1

def runIrdl : IO UInt32 := do
  let log ← IO.mkRef ""
  let bin ← llvmBin
  say log s!"== irdl  ({← stamp})"
  let mut fails := 0
  for d in ["pirtm", "hcalc"] do
    let f := s!"mlir/dialects/{d}.irdl.mlir"
    let o ← proc s!"{bin}/mlir-opt" #[f, "-o", "/dev/null"]
    if o.exitCode != 0 then fails := fails + 1
    say log s!"{if o.exitCode == 0 then "PASS" else "FAIL"} parse {f}"
  let jdemo ← readLines ("logs" / "j" / "demo.out")
  IO.FS.createDirAll (".lake" / "mlir")
  for (name, dialect, libs, file, _, _) in ← customPrograms jdemo do
    let vf : FilePath := ".lake" / "mlir" / s!"{name}.custom.mlir"
    IO.FS.writeFile vf ((← concatFiles libs) ++ (← IO.FS.readFile ("mlir" / file)))
    let ok ← proc s!"{bin}/mlir-opt" #[s!"--irdl-file=mlir/dialects/{dialect}.irdl.mlir", vf.toString, "-o", "/dev/null"]
    let no ← proc s!"{bin}/mlir-opt" #[vf.toString, "-o", "/dev/null"]
    let pass := ok.exitCode == 0 && no.exitCode != 0
    if !pass then fails := fails + 1
    say log s!"{if pass then "PASS" else "FAIL"} {file}: verifies with --irdl-file={dialect} (exit {ok.exitCode}); rejected without it (exit {no.exitCode})"
  let inv := ["hcalc_bad_operand_type.mlir", "hcalc_bad_result_count.mlir", "pirtm_bad_operand_count.mlir"]
  for f in inv do
    let dialect := (f.splitOn "_").head!
    let o ← proc s!"{bin}/mlir-opt" #[s!"--irdl-file=mlir/dialects/{dialect}.irdl.mlir", s!"mlir/custom/invalid/{f}", "-o", "/dev/null"]
    let pass := o.exitCode != 0
    if !pass then fails := fails + 1
    let msg := (linesOf o.stderr).head?.getD ""
    say log s!"{if pass then "PASS" else "FAIL"} mlir/custom/invalid/{f} rejected (exit {o.exitCode}): {msg}"
  say log s!"irdl: {if fails == 0 then "PASS" else s!"FAIL ({fails})"}"
  writeLog ("logs" / "mlir" / "IRDL.txt") (← log.get)
  return if fails == 0 then 0 else 1

def isCircuitLine (l : String) : Bool :=
  l.startsWith "QGate" || l.startsWith "Inputs" || l.startsWith "Outputs" || l.startsWith "Total" ||
  l.startsWith "Qubits" || l.startsWith "-- circuit" || l.isEmpty ||
  (match (l.toList.dropWhile (· == ' ')) with
   | c :: cs => l.startsWith " " && c.isDigit && (cs.dropWhile Char.isDigit).head? == some ':'
   | [] => false)

def runQuipper : IO UInt32 := do
  let log ← IO.mkRef ""
  say log s!"== quipper  ({← stamp})"
  let home ← envOr "HOME" "/home/box"
  let ghcup ← envOr "GHCUP_BIN" s!"{home}/.ghcup/bin"
  let tinfo ← envOr "TINFO5_DIR" s!"{home}/.local/lib/tinfo5"
  let path ← envOr "PATH" "/usr/bin:/bin"
  let env := #[("PATH", some s!"{ghcup}:{path}"), ("LD_LIBRARY_PATH", some tinfo)]
  let b ← proc s!"{ghcup}/cabal" #["build", "-v0", "pirtm-quipper"] (cwd := some "quipper") (env := env)
  say log s!"cabal build pirtm-quipper -> exit {b.exitCode}"
  if b.exitCode != 0 then
    say log b.stderr
    writeLog ("logs" / "quipper" / "SUMMARY.txt") (← log.get)
    return 1
  let r ← proc s!"{ghcup}/cabal" #["run", "-v0", "pirtm-quipper"] (cwd := some "quipper") (env := env)
  writeLog ("logs" / "quipper" / "run.out") r.stdout
  let out := linesOf r.stdout
  let gates := out.filter (·.startsWith "QGate")
  say log s!"cabal run pirtm-quipper -> exit {r.exitCode}, {out.length} lines ({gates.length} printed gate lines) -> logs/quipper/run.out"
  let numeric := out.filter (fun l => !isCircuitLine l)
  let expected ← readLines (expectedDir / "quipper.txt")
  let ok := r.exitCode == 0 && numeric == expected
  say log s!"{if ok then "PASS" else "FAIL"} simulated values vs Python PIRTM (expected/quipper.txt): {firstDiff numeric expected}"
  writeLog ("logs" / "quipper" / "SUMMARY.txt") (← log.get)
  return if ok then 0 else 1

partial def leanFiles (d : FilePath) : IO (Array FilePath) := do
  let mut acc := #[]
  for e in ← d.readDir do
    if e.fileName.startsWith "." || e.fileName == "quipper" || e.fileName == "logs" then continue
    if ← e.path.isDir then acc := acc ++ (← leanFiles e.path)
    else if e.fileName.endsWith ".lean" then acc := acc.push e.path
  return acc

def isIdent (c : Char) : Bool := c.isAlphanum || c == '_' || c == '\'' || c == '.'

/-- whole-word occurrences of `w` in `s` -/
def wordCount (s w : String) : Nat :=
  let parts := s.splitOn w
  let rec go : List String → Nat
    | a :: b :: rest =>
      let before := a.toList.getLast?.map isIdent |>.getD false
      let after := b.toList.head?.map isIdent |>.getD false
      (if !before && !after then 1 else 0) + go (b :: rest)
    | _ => 0
  go parts

/-- The two forbidden proof-escape keywords, spelled in pieces so that this
file itself does not contain them as words. -/
def escapeWords : List String := ["sor" ++ "ry", "ad" ++ "mit"]

def runLean : IO UInt32 := do
  let log ← IO.mkRef ""
  say log s!"== lean  ({← stamp})"
  let lake ← envOr "LAKE" "lake"
  let b ← proc lake #["build"]
  writeLog ("logs" / "lean" / "build.log") (b.stdout ++ b.stderr)
  say log s!"lake build -> exit {b.exitCode} -> logs/lean/build.log"
  let mut hits := 0
  for f in ← leanFiles "." do
    let s ← IO.FS.readFile f
    let n := escapeWords.foldl (fun acc w => acc + wordCount s w) 0
    if n > 0 then say log s!"  {f}: {n} occurrences of {escapeWords}"
    hits := hits + n
  say log s!"occurrences of {escapeWords} (whole words) in project .lean files: {hits}"
  let a ← proc lake #["env", "lean", "tools/AxiomAudit.lean"]
  writeLog ("logs" / "lean" / "axioms.txt") (a.stdout ++ a.stderr)
  let declared := (linesOf a.stdout).filter (·.startsWith "  axiom ")
  say log s!"axiom audit -> exit {a.exitCode}, {declared.length} axioms declared in project modules -> logs/lean/axioms.txt"
  let ok := b.exitCode == 0 && hits == 0 && a.exitCode == 0
  say log s!"lean: {if ok then "PASS" else "FAIL"}"
  writeLog ("logs" / "lean" / "SUMMARY.txt") (← log.get)
  return if ok then 0 else 1

def runCpp : IO UInt32 := do
  let log ← IO.mkRef ""
  say log s!"== cpp  ({← stamp})"
  IO.FS.createDirAll (".lake" / "cpp")
  let bin : FilePath := ".lake" / "cpp" / "test_goldilocks"
  let c ← proc "g++" #["-O2", "-std=c++17", "-o", bin.toString, "mlir/custom/Goldilocks/test_goldilocks.cpp"]
  say log s!"g++ -O2 -std=c++17 test_goldilocks.cpp -> exit {c.exitCode}"
  if c.exitCode != 0 then
    if !c.stderr.isEmpty then say log c.stderr
    writeLog ("logs" / "cpp" / "SUMMARY.txt") (← log.get)
    return 1
  let r ← proc bin.toString #[]
  writeLog ("logs" / "cpp" / "test_goldilocks.out") r.stdout
  let first := (linesOf r.stdout).head?.getD ""
  say log s!"test_goldilocks -> exit {r.exitCode}: {first}"
  let ok := r.exitCode == 0 && (linesOf r.stdout).any (·.startsWith "PASS:")
  say log s!"cpp: {if ok then "PASS" else "FAIL"}"
  writeLog ("logs" / "cpp" / "SUMMARY.txt") (← log.get)
  return if ok then 0 else 1

script j do runJ
script mlir do runMlir
script irdl do runIrdl
script quipper do runQuipper
script lean do runLean
script cpp do runCpp
script all do
  let mut rcs := #[]
  for (n, act) in [("j", runJ), ("mlir", runMlir), ("cpp", runCpp), ("irdl", runIrdl), ("quipper", runQuipper), ("lean", runLean)] do
    let rc ← act
    rcs := rcs.push s!"{n}: {if rc == 0 then "PASS" else "FAIL"}"
  let txt := String.intercalate "\n" rcs.toList
  IO.println txt
  writeLog ("logs" / "SUMMARY.txt") (s!"{← stamp}\n" ++ txt ++ "\n")
  return if rcs.all (·.endsWith "PASS") then 0 else 1
