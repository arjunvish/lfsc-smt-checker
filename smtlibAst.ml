let concat_sp_sep_2 a b = "("^a^" "^b^")"
let concat_sp_sep_3 a b c = "("^a^" "^b^" "^c^")"
let concat_sp_sep_4 a b c d = "("^a^" "^b^" "^c^" "^d^")"
let concat_sp_sep_5 a b c d e = "("^a^" "^b^" "^c^" "^d^" "^e^")"
let concat_sp_sep_6 a b c d e f = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^")"
let concat_sp_sep_7 a b c d e f g = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^" "^g^")"
let concat_sp_sep_8 a b c d e f g h = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^" "^g^" "^h^")"

type sorted_term = 
  | BTrue
  | BFalse
  | TVar of string
  | Ite of formula * sorted_term * sorted_term
and formula = 
  | True
  | False
  | Var of string
  | Not of formula
  | And of formula * formula
  | Or of formula * formula
  | Impl of formula * formula
  | Eq of sorted_term * sorted_term
  | Xor of formula * formula

type t = formula list

let rec to_string_sorted_term =
  function
  | BTrue -> "true"
  | BFalse -> "false"
  | TVar v -> v
  | Ite (x,y,z) -> concat_sp_sep_4 "ite" (to_string_form x) (to_string_sorted_term y) (to_string_sorted_term z)
and to_string_form = 
  function
  | True -> "true"
  | False -> "false"
  | Var v -> v
  | Not f -> concat_sp_sep_2 "not" (to_string_form f)
  | And (x,y) -> concat_sp_sep_3 "and" (to_string_form x) (to_string_form y)
  | Or (x,y) -> concat_sp_sep_3 "or" (to_string_form x) (to_string_form y)
  | Impl (x,y) -> concat_sp_sep_3 "=>" (to_string_form x) (to_string_form y)
  | Eq (x,y) -> concat_sp_sep_3 "=" (to_string_sorted_term x) (to_string_sorted_term y)
  | Xor (x,y) -> concat_sp_sep_3 "xor" (to_string_form x) (to_string_form y)

let rec to_string (l : t) = 
  let l_str = (List.map (to_string_form) (l)) in
  (String.concat "\n" l_str)