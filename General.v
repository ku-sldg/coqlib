Require Import Coq.Program.Equality.
Require Import Tactics.Combinators.

(* Modified from the `StructTact` library definition:
   https://github.com/uwplse/StructTact/blob/a0f4aa3491edf27cf70ea5be3190b7efa8899971/theories/StructTactics.v#L17
 *)
Ltac inv H := inversion H; subst; try contradiction.

(* Overwrite exists tactic to support multiple instantiations 
   (up to four)
 *)
Tactic Notation "exists" uconstr(x1) :=
  exists x1.
Tactic Notation "exists" uconstr(x1) uconstr(x2) :=
  exists x1; exists x2.
Tactic Notation "exists" uconstr(x1) uconstr(x2) uconstr(x3) :=
  exists x1 x2; exists x3.
Tactic Notation "exists" uconstr(x1) uconstr(x2) uconstr(x3) uconstr(x4) :=
  exists x1 x2 x3; exists x4.


(* destruct variants *)

Tactic Notation "destruct" "multi" hyp(h1) hyp(h2) :=
  destruct h1; destruct h2.
Tactic Notation "destruct" "multi" hyp(h1) hyp(h2) hyp(h3) :=
  destruct multi h1 h2; destruct h3.
Tactic Notation "destruct" "multi" hyp(h1) hyp(h2) hyp(h3) hyp(h4) :=
  destruct multi h1 h2 h3; destruct h4.

Tactic Notation "destruct" "exists" hyp(H) ident(id) :=
  destruct H as [id H].
Tactic Notation "destruct" "exists" hyp(H) ident(id1) ident(id2) :=
  destruct H as [id1 [id2 H]].
Tactic Notation "destruct" "exists" hyp(H) ident(id1) ident(id2) ident(id3) :=
  destruct H as [id1 [id2 [id3 H]]].
Tactic Notation "destruct" "exists" hyp(H) ident(id1) ident(id2) ident(id3) ident (id4) :=
  destruct H as [id1 [id2 [id3 [id4 H]]]].

Tactic Notation "destruct" "or" hyp(H) := destruct H as [H|H].

(* Clear variants. Tactics postfixed with "c" clear a hypothesis
   after using it.
 *)

Ltac invc H := inv H; clear H.
Tactic Notation "applyc" hyp(H) := apply H; clear H.
Tactic Notation "applyc" hyp(H) "in" hyp(H2) := apply H in H2; clear H.
Tactic Notation "eapplyc" hyp(H) := eapply H; clear H.
Tactic Notation "eapplyc" hyp(H) "in" hyp(H2) := eapply H in H2; clear H.

Ltac specializec H x := specialize (H x); clear x.


(* Unfold one layer *)
Tactic Notation "expand" constr(x) := unfold x; fold x.
Tactic Notation "expand" constr(x) "in" hyp(H) := unfold x in H; fold x in H.
Tactic Notation "expand" constr(x) "in" "*" := unfold x in *; fold x in *.


(* `pose new proof`, variant of `pose proof` that fails if such a hypothesis
   already exists in the context. Useful for automation which saturates the 
   context with generated facts
 *)

Ltac fail_if_in_hyps H :=
  let t := type of H in
  lazymatch goal with 
  | [_: t |- _] => fail "This proposition is already assumed"
  | [_: _ |- _] => idtac
  end.

Tactic Notation "pose" "new" "proof" constr(H) :=
  fail_if_in_hyps H;
  pose proof H.

Tactic Notation "pose" "new" "proof" constr(H) "as" ident(H2) :=
  fail_if_in_hyps H;
  pose proof H as H2.


(* Maximally recursive split *)
Ltac _max_split := try (split; _max_split).
Tactic Notation "max" "split" := _max_split.


(* Copy a hypothesis *)
Tactic Notation "copy" hyp(H) :=
  let H' := fresh H in
  pose proof H as H'.

Tactic Notation "copy" hyp(H) ident(I) := pose proof H as I.

(* When `unset x` is invoked with hypothesis `x := t` (commonly introduced by 
   tactic `set`), replaces all instances of `x` with `t`, and clears `x`.
 *)
Ltac unset x := unfold x in *; clear x.


(* A sylistic alias for `admit`. Used to distinguish admitted goals
   which you know how to solve and that you plan come back to once the 
   difficult proof goals are solved.
 *)
Ltac todo := admit.


(* `cuth`. Stands for "cut hypothesis" (unfortunately, the standard library alread
   has a tactic called `cut`). Conduct forward reasoning by eliminating the assumption 
   in an implication. Optionally, you can supply a tactic with the `by` clause.
   E.g.:
   with hypothesis `H: x = x -> foo`, one can invoke `cuth H by reflexivity`. 
   The hypothesis is then replaced with `H: foo`.
 *)

Tactic Notation "cuth" hyp(H):=
  match type of H with
  | ?x -> _ =>
      let H' := fresh in 
      assert (H': x); 
        [| specialize (H H'); clear H']
  end.

Tactic Notation "cuth" hyp(H) "by" tactic(tac) :=
  cuth H; [solve [tac]|].


(* "max" variant of `cuth`. Invokes cuth on each assumption of a chained implication *)

Ltac _max_cuth H := try (cuth H; [|_max_cuth]).
Tactic Notation "max" "cuth" hyp(H) := _max_cuth.

Ltac _max_cuth_by H tac := try (cuth H; [tac|_max_cuth]).
Tactic Notation "max" "cuth" hyp(H) "by" tactic(tac) := _max_cuth_by H tac.

(* Solve a (registered) reflexive relation by proving the arguments equal *)
Ltac reflexive := 
  match goal with 
  | |- _ ?x ?y =>
      replace x with y;
        [ reflexivity
        | try easy; symmetry
        ]
  end.


(* Dependent inv
   Sometime, inversion leaves behind equalities of existT terms. This tactic 
   uses dependent destruction to break these into further equalities.
   (Note, this leverages axioms about equality)
 *)

Ltac dep_destr_sigma :=
  repeat match goal with 
  | H: existT _ _ _ = existT _ _ _ |- _ => dependent destruction H
  end.

Tactic Notation "dependent" "inv" hyp(H) :=
  inv H;
  dep_destr_sigma.

Tactic Notation "dependent" "invc" hyp(H) :=
  invc H;
  dep_destr_sigma.