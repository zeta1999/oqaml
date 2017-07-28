module M = Owl.Dense.Matrix.C;;
module Math = Owl.Maths;;
module V = Owl.Dense.Vector.C;;
module C = Complex;;
module S = Core_extended.Sampler;;
module U = Utils;;
include U;;
open Primitives;;


(** QVM supporting ProtoQuil *)
type gate =
  I of int
  | X of int
  | Y of int
  | Z of int
  | H of int
  | RX of float * int
  | RY of float * int
  | RZ of float * int
  | CNOT of int*int
  | SWAP of int*int

type qvm =
  { num_qubits: int;
    wf : V.vec;
  }

let state_list qvm =
  let r = U.range 0 (U.int_pow 2 qvm.num_qubits) in
  List.map (fun x -> U.pad_list qvm.num_qubits (U._reverse_bin_rep x)) r;;

let create_qvm_in_state num_qubits state =
  let _init_state num_qubits = ((U.int_pow 2 num_qubits) |> V.unit_basis) 0 |> V.transpose in
  let _wf = match state with None -> _init_state num_qubits | Some x -> x in
  {num_qubits = num_qubits;
   wf = _wf;
  };;

let init_qvm num_qubits = create_qvm_in_state num_qubits None;;

let tensor_up_single_q_gate n q g =
  U.kron_up (U._buildList 0 n q g);;



let swapagator ctrl trgt nqubit =
  (** This constructs the full swapagatpr to bring a target qubit [trgt] next to the control qubit [ctrl].
      We first construct a padding of identities to the left of [ctrl] then build the swapagator kernel of distance
      (trgt - ctrl) and finally pad more identities to the right of [trgt] to fill up to the number of qubits in
      the qvm. Finally we kron up the resulting list to get the full swapagator. *)
  let _swapagator_kernel dist =
    (** This method is a helper to multiply all the individual nearest neighbor SWAPs to propagate a qubit state
        over a distance [dist]*)
    let _multi_dot dim = List.fold_left M.dot (M.eye (U.int_pow 2 dim)) in
    let rec _swapagator_sub_kernels i dist =
      let x = i+1 in
      (** We need to account for the fact that we have a 2-Qubit gate already. Hence when constructing
          the list of propagators we make the distance short by one as we already have a lifted gate. E.g.
          a given swapagator for 4 particles is [(kron swap id id) * (kron id swap id) * (kron id id swap)],
          which is of dimension 16. We can construct the individual lists by using the buildList func where the
          qubit indicates the position of the pair, leading to the reduction by 1 in length of the lists.*)
      if i < dist-1 then (U.kron_up (U._buildList 0 (dist-1) i swap))::(_swapagator_sub_kernels x dist)
      else []
    in
    _multi_dot dist (_swapagator_sub_kernels 0 dist)
  in
  U.kron_up ((U._buildList 0 (ctrl+1) ctrl id)@[(_swapagator_kernel (trgt-ctrl))]@(U._buildList 0 (nqubit-trgt-1) trgt id));;

let get_2q_gate n ctrl trgt g=
  (**Currently this only support control qubits left of the target subits. The implementation of reverse
   is merely a 180 degree rotation of the resulting matrix. Howver, I need to double check this to make
   sure of that. *)
  let swpgtr = swapagator ctrl trgt n in
  let gt = U.kron_up (_build_nn_2q_gate_list 0 n ctrl g) in
  M.dot swpgtr (M.dot gt swpgtr);;


let apply_gate i qvm =
  match i with
  | I(x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x id) qvm.wf}
  | X(x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x sx) qvm.wf}
  | Y(x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x sy) qvm.wf}
  | Z(x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x sz) qvm.wf}
  | H(x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x h) qvm.wf}
  | RX(t,x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x (rx t)) qvm.wf}
  | RY(t,x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x (ry t)) qvm.wf}
  | RZ(t,x) -> {num_qubits=qvm.num_qubits; wf = V.dot (tensor_up_single_q_gate qvm.num_qubits x (rz t)) qvm.wf}
  | CNOT(x,y) -> {num_qubits=qvm.num_qubits; wf = V.dot (get_2q_gate qvm.num_qubits x y cnot) qvm.wf}
  | SWAP(x,y) -> {num_qubits=qvm.num_qubits; wf = V.dot (get_2q_gate qvm.num_qubits x y swap) qvm.wf};;

let get_probs qvm =
  qvm.wf |> V.to_array |> Array.to_list |> (List.map (fun x -> (C.norm x) ** 2.0));;

let measure qvm n =
  let smplr = S.create (List.map2 (fun x y -> (x, y)) (state_list qvm) (get_probs qvm)) in
  let rec sample_state smplr n i =
    let j = i+1 in
    if j < n then S.sample(smplr)::(sample_state smplr n j)
    else []
  in
  sample_state smplr n 0;;


(** Classical Bit Register *)
type instr =
  NOT of int
  | AND of int * int
  | OR of int * int

type register = REG of int list;;

let bool_of_int i = if i==1 then true else false;;
let int_of_bool b = if b then 1 else 0;;

let get_reg_vals reg =
    match reg with
    | REG(lst) -> Array.of_list lst;;

let bit_flip b = (1 - b);;
let bit_and ctr tar = if (ctr == 1 && tar == 1) then 1 else 0;;
let bit_or ctr tar = if (ctr == 1 || tar == 1) then 1 else 0;;

let flip x arr =
  arr.(x) <- bit_flip arr.(x);
  arr;;

let cand x y arr =
  arr.(y) <-  bit_and arr.(x) arr.(y);
  arr;;

let cor x y arr =
  arr.(y) <- bit_or arr.(x) arr.(y);
  arr;;

let apply i r =
  match i with
  | NOT(x) -> REG(Array.to_list(flip x (get_reg_vals r)))
  | AND(x, y) -> REG(Array.to_list(cand x y (get_reg_vals r)))
  | OR(x, y) -> REG(Array.to_list(cor x y (get_reg_vals r)));;
