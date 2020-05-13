%{
(* This parser is adapted from SMTCoq's SMTLIB parser *)

open Lexing
open Format
open SmtlibAst

(* Hashtable to store function definitions *)
let fun_map = Hashtbl.create 10

(* Traverse the term "body" and replace all variable occurrences of
   x by y*)
let rec traverse_and_replace_let (x : sorted_term) (y : sorted_term) (body : sorted_term) : sorted_term = 
match body with
  | True | False | Bvbin _ | Bvhex _ | Error _ -> body
  | Var a -> (match x with 
              | Var m when (a = m) -> y
              | Var _ -> x
              | _ -> Error "Non-variables involved in formal parameters of let")
  | Not a -> Not (traverse_and_replace_let x y a)
  | And (a,b) -> And ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Or (a,b) -> Or ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Impl (a,b) -> Impl ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Xor (a,b) -> Xor ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))      
  | Eq (a,b) -> Eq ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Ite (f,a,b) -> Ite (f, (traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvult (a,b) -> Bvult ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvule (a,b) -> Bvule ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvugt (a,b) -> Bvugt ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvuge (a,b) -> Bvuge ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvslt (a,b) -> Bvslt ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsle (a,b) -> Bvsle ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsgt (a,b) -> Bvsgt ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsge (a,b) -> Bvsge ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Appl (s,args) -> let new_args = (List.map (traverse_and_replace_let x y) args) in Appl (s,new_args)
  | Select (a,b) -> Select ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Store (a,b,c) -> Store ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b), (traverse_and_replace_let x y c))
  | Bvand (a,b) -> Bvand ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvor (a,b) -> Bvor ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvxor (a,b) -> Bvxor ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvnand (a,b) -> Bvnand ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvnor (a,b) -> Bvnor ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvxnor (a,b) -> Bvxnor ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvmul (a,b) -> Bvmul ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvadd (a,b) -> Bvadd ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsub (a,b) -> Bvsub ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvudiv (a,b) -> Bvudiv ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvurem (a,b) -> Bvurem ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsdiv (a,b) -> Bvsdiv ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsrem (a,b) -> Bvsrem ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvsmod (a,b) -> Bvsmod ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvshl (a,b) -> Bvshl ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvlshr (a,b) -> Bvlshr ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvashr (a,b) -> Bvashr ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvconcat (a,b) -> Bvconcat ((traverse_and_replace_let x y a), (traverse_and_replace_let x y b))
  | Bvneg a -> Bvneg (traverse_and_replace_let x y a)
  | Bvnot a -> Bvnot (traverse_and_replace_let x y a)
  | Bvextract (i,j,a) -> Bvextract (i,j, (traverse_and_replace_let x y a))
  | Bvzeroext (i,a) -> Bvzeroext (i, (traverse_and_replace_let x y a))
  | Bvsignext (i,a) -> Bvsignext (i, (traverse_and_replace_let x y a))
  | Bvlrotate (i,a) -> Bvlrotate (i, (traverse_and_replace_let x y a))
  | Bvrrotate (i,a) -> Bvrrotate (i, (traverse_and_replace_let x y a))
  | Bvrepeat (i,a) -> Bvrepeat (i, (traverse_and_replace_let x y a))
  | Bvcomp (a,b) -> Bvcomp ((traverse_and_replace_let x y a)  , (traverse_and_replace_let x y b))

(* For each of the variable pairs (x,y) in arg pairs, 
   replace x by y in body *)  
let rec traverse_and_replace_all_let (arg_pairs : (sorted_term * sorted_term) list) (body : sorted_term) : sorted_term =
match arg_pairs with 
  | (x,y) :: t -> traverse_and_replace_all_let t (traverse_and_replace_let x y body)
  | [] -> body


(* Traverse the term "body" and replace all variable occurrences of
   x by y*)
let rec traverse_and_replace (x : sorted_term) (y : sorted_term) (body : sorted_term) : sorted_term = 
match body with
  | True | False | Bvbin _ | Bvhex _ | Error _ -> body
  | Var a -> (match x,y with 
              | Var m, Var n when (a = m) -> y
              | Var _, Var _ -> Var a
              | _ -> Error "Non-variables involved in actual/formal parameters of define-fun")
  | Not a -> Not (traverse_and_replace x y a)
  | And (a,b) -> And ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Or (a,b) -> Or ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Impl (a,b) -> Impl ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Xor (a,b) -> Xor ((traverse_and_replace x y a), (traverse_and_replace x y b))      
  | Eq (a,b) -> Eq ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Ite (f,a,b) -> Ite (f, (traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvult (a,b) -> Bvult ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvule (a,b) -> Bvule ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvugt (a,b) -> Bvugt ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvuge (a,b) -> Bvuge ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvslt (a,b) -> Bvslt ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsle (a,b) -> Bvsle ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsgt (a,b) -> Bvsgt ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsge (a,b) -> Bvsge ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Appl (s,args) -> let new_args = (List.map (traverse_and_replace x y) args) in Appl (s,new_args)
  | Select (a,b) -> Select ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Store (a,b,c) -> Store ((traverse_and_replace x y a), (traverse_and_replace x y b), (traverse_and_replace x y c))
  | Bvand (a,b) -> Bvand ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvor (a,b) -> Bvor ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvxor (a,b) -> Bvxor ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvnand (a,b) -> Bvnand ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvnor (a,b) -> Bvnor ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvxnor (a,b) -> Bvxnor ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvmul (a,b) -> Bvmul ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvadd (a,b) -> Bvadd ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsub (a,b) -> Bvsub ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvudiv (a,b) -> Bvudiv ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvurem (a,b) -> Bvurem ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsdiv (a,b) -> Bvsdiv ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsrem (a,b) -> Bvsrem ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvsmod (a,b) -> Bvsmod ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvshl (a,b) -> Bvshl ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvlshr (a,b) -> Bvlshr ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvashr (a,b) -> Bvashr ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvconcat (a,b) -> Bvconcat ((traverse_and_replace x y a), (traverse_and_replace x y b))
  | Bvneg a -> Bvneg (traverse_and_replace x y a)
  | Bvnot a -> Bvnot (traverse_and_replace x y a)
  | Bvextract (i,j,a) -> Bvextract (i,j, (traverse_and_replace x y a))
  | Bvzeroext (i,a) -> Bvzeroext (i, (traverse_and_replace x y a))
  | Bvsignext (i,a) -> Bvsignext (i, (traverse_and_replace x y a))
  | Bvlrotate (i,a) -> Bvlrotate (i, (traverse_and_replace x y a))
  | Bvrrotate (i,a) -> Bvrrotate (i, (traverse_and_replace x y a))
  | Bvrepeat (i,a) -> Bvrepeat (i, (traverse_and_replace x y a))
  | Bvcomp (a,b) -> Bvcomp ((traverse_and_replace x y a), (traverse_and_replace x y b))

(* For each of the variable pairs (x,y) in arg pairs, 
   replace x by y in body *)  
let rec traverse_and_replace_all (arg_pairs : (sorted_term * sorted_term) list) (body : sorted_term) : sorted_term =
match arg_pairs with 
  | (x,y) :: t -> traverse_and_replace_all t (traverse_and_replace x y body)
  | [] -> body

(* Replace all formal_args by actual_args in the term body *)
let replace (formal_args : sorted_term list) (actual_args : sorted_term list) (body : sorted_term) : sorted_term=
  let arg_pairs = List.combine formal_args actual_args in
  traverse_and_replace_all arg_pairs body

(* Take a multi-arity operator in SMTLIB and build a tree for its 
   right associative version in LFSC *)
let rec build_tree_right_ass (s : string) (args : sorted_term list) : sorted_term =
  if (List.length args = 2) then
    match s with
      | "and" -> And ((List.nth args 0),(List.nth args 1))
      | "or" -> Or ((List.nth args 0),(List.nth args 1))
      | _ -> Error "Error with multi-arity right associative operator"
  else
    match s with
      | "and" -> And ((List.nth args 0),(build_tree_right_ass s (List.tl args)))
      | "or" -> Or ((List.nth args 0),(build_tree_right_ass s (List.tl args)))
      | _ -> Error "Error with multi-arity right associative operator"

(* Take a multi-arity operator in SMTLIB and build a tree for its 
   keft associative version in LFSC *)
let rec build_tree_left_ass (s : string) (args : sorted_term list) : sorted_term =
  let rev_args = (List.rev args) in
  if (List.length args = 2) then
    match s with
      | "xor" -> Xor ((List.nth rev_args 0),(List.nth rev_args 1))
      | "bvand" -> Bvand ((List.nth rev_args 0),(List.nth rev_args 1))
      | "bvor" -> Bvor ((List.nth rev_args 0),(List.nth rev_args 1))
      | "bvxor" -> Bvxor ((List.nth rev_args 0),(List.nth rev_args 1))
      | "bvadd" -> Bvadd ((List.nth rev_args 0),(List.nth rev_args 1))
      | "bvmul" -> Bvmul ((List.nth rev_args 0),(List.nth rev_args 1))
      | _ -> Error "Error with multi-arity left associative operator"
  else
    match s with
      | "xor" -> Xor ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | "bvand" -> Bvand ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | "bvor" -> Bvor ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | "bvxor" -> Bvxor ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | "bvadd" -> Bvadd ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | "bvmul" -> Bvmul ((build_tree_left_ass s (List.tl rev_args)),(List.nth rev_args 0))
      | _ -> Error "Error with multi-arity left associative operator"

(* The mod operator in OCaml implements remainder 
with respect to numeral division. Since numeral division
in OCaml rounds toward 0, we design modulo which considers 
division that rounds toward negative infinity. 
For example, -1 mod 8 is -1 (with quotient 0) in OCaml, 
we want it to be 7 (with quotient -1).
While considering a mod b, the OCaml mod operator will do what 
we want when a and b are positive. The following function will 
additionally do what we want when a is negative; it wont do what 
we want when b is negative, but that's okay since 
we don't consider cases of 
modulo-n arithmetic where n is negative. *)
let modulo (x : Numeral.t) (y : Numeral.t) : Numeral.t =
  let result = (Numeral.rem x y) in
    if (Numeral.geq result Numeral.zero) then result
  else (Numeral.add result y)

(* Function that calculates the nth power of two *)
let rec pow2 (n : Numeral.t) : Numeral.t =
  if (Numeral.equal n Numeral.zero) then
    Numeral.one
  else
    Numeral.mult (Numeral.succ (Numeral.one)) 
                 (pow2 (Numeral.sub n Numeral.one))

(* Function that returns unsigned fixed-width int or bitvector version of a numeral *)
let bv_dec_to_bin (i : Numeral.t) (size : Numeral.t) : string =
  (* x = 2^N for ubvN, where we need to 
  do n modulo x on the input n *)
  let m = pow2 size in
  let n = modulo i m in
  (* Tail-recursive function that converts n to type t,
  which is a list of bools *)
  let rec convert (acc : bool list) (l : Numeral.t) (n : Numeral.t) =
    if (Numeral.gt n Numeral.zero) then
      convert ((Numeral.equal (Numeral.rem n (Numeral.of_int 2)) Numeral.one) :: acc) 
              (Numeral.add l Numeral.one) (Numeral.div n (Numeral.of_int 2))
    else (acc, l)
  in
  let bv, l = convert [] Numeral.zero n in
  (* For n-bit BV, pad upto n bits with 0s *)
  let rec pad (bv : bool list) (l :Numeral.t) =
    if (Numeral.gt l Numeral.zero) then 
      pad (false :: bv) (Numeral.sub l Numeral.one) 
    else 
      bv
  in
  let rec bv_to_string (b : bool list) : string = 
    match b with
    | true :: t -> "1"^(bv_to_string t)
    | false :: t -> "0"^(bv_to_string t)
    | [] -> ""
  in
  ("#b"^(bv_to_string (pad bv (Numeral.sub size l))))

(*
let bv_dec_to_bin (i : int) (l : int) : string =
  let modulo (x : int) (y : int) : int =
    let result = (x mod y) in
      if (result >= 0) then result
      else (result + y) 
  in
  let rec pow2 (n : int) : int =
    if (n = 0) then 1
    else (2 * (pow2 (n - 1))) 
  in
  (* x = 2^N for ubvN, where we need to 
  do n modulo x on the input n *)
  let m = pow2 l in
  let n = modulo i m in
  (* Tail-recursive function that converts n to type t,
  which is a list of bools *)
  let rec convert acc (l : int) (n : int) =
    if (n > 0) then convert (((n mod 2) = 1) :: acc) (l + 1) (n / 2)
    else (acc, l)
  in
  let bv, l_new = convert [] 0 n in
  (* For n-bit BV, pad upto n bits with 0s *)
  let rec pad (bv : bool list) (l : int) =
    if (l > 0) then (pad (false :: bv) (l - 1))
    else bv
  in
  let rec bv_to_string (b : bool list) : string = 
    match b with
    | true :: t -> "1"^(bv_to_string t)
    | false :: t -> "0"^(bv_to_string t)
    | [] -> ""
  in ("#b"^(bv_to_string (pad bv (l - l_new))))
*)
let concat_sp_sep_1 a = "("^a^")"
let concat_sp_sep_2 a b = "("^a^" "^b^")"
let concat_sp_sep_3 a b c = "("^a^" "^b^" "^c^")"
let concat_sp_sep_4 a b c d = "("^a^" "^b^" "^c^" "^d^")"
let concat_sp_sep_5 a b c d e = "("^a^" "^b^" "^c^" "^d^" "^e^")"
let concat_sp_sep_6 a b c d e f = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^")"
let concat_sp_sep_7 a b c d e f g = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^" "^g^")"
let concat_sp_sep_8 a b c d e f g h = "("^a^" "^b^" "^c^" "^d^" "^e^" "^f^" "^g^" "^h^")"
%}

%token <string> IDENT
%token <int> INT
%token <string> BVDEC
%token <string> BVBIN
%token <string> BVHEX
%token LPAREN RPAREN COLON EOF SETLOGIC TRUE FALSE NOT AND OR IMPL XOR EQUALS ITE BOOL HASH_SEMI
%token DECLARECONST DECLAREFUN DECLARESORT DEFINEFUN CHECKSAT EXIT LET ASSERT ARRAY SELECT STORE
%token BITVEC INDEX BVAND BVOR BVXOR BVNAND BVNOR BVXNOR BVMUL BVADD BVSUB BVUDIV BVUREM
%token BVSDIV BVSREM BVSMOD BVSHL BVLSHR BVASHR BVCONCAT BVNEG BVNOT BVLROTATE BVRROTATE BVCOMP
%token BVEXTRACT BVZEROEXT BVSIGNEXT BVREPEAT BVULT BVULE BVUGT BVUGE BVSLT BVSLE BVSGT BVSGE


%start file
%type <unit> file
%%
sort:
  | BOOL
    { "Bool" }
  | IDENT
    { $1 }
  | LPAREN ARRAY sort sort RPAREN
    { (concat_sp_sep_3 "Array" $3 $4) }
  | LPAREN INDEX BITVEC INT RPAREN
    { (concat_sp_sep_3 "_" "BitVec" (string_of_int $4)) }
;

letarg:
  | LPAREN IDENT sorted_term RPAREN
    { (Var $2, $3) }
;

letargs:
  | LPAREN l=list(letarg) RPAREN
    { l }
;

sorted_term:
  | TRUE { True }
  | FALSE { False }
  | LPAREN NOT s=sorted_term RPAREN 
    { Not s }
  | LPAREN AND args=list(sorted_term) RPAREN
    { (build_tree_right_ass "and" args) }
  | LPAREN OR args=list(sorted_term) RPAREN
    { (build_tree_right_ass "or" args) }
  | LPAREN IMPL s1=sorted_term s2=sorted_term RPAREN
    { Impl (s1, s2) }
  | LPAREN XOR args=list(sorted_term) RPAREN
    { (build_tree_left_ass "xor" args) }
  | LPAREN EQUALS s1=sorted_term s2=sorted_term RPAREN
    { Eq (s1, s2) } 
  | LPAREN ITE s1=sorted_term s2=sorted_term s3=sorted_term RPAREN
    { Ite (s1, s2, s3) }
  | LPAREN LET letargs sorted_term RPAREN
    { (traverse_and_replace_all_let $3 $4) }
  | LPAREN BVULT s1=sorted_term s2=sorted_term RPAREN
    { Bvule (s1, s2) }
  | LPAREN BVULE s1=sorted_term s2=sorted_term RPAREN
    { Bvule (s1, s2) }
  | LPAREN BVUGT s1=sorted_term s2=sorted_term RPAREN
    { Bvugt (s1, s2) }
  | LPAREN BVUGE s1=sorted_term s2=sorted_term RPAREN
    { Bvuge (s1, s2) }
  | LPAREN BVSLT s1=sorted_term s2=sorted_term RPAREN
    { Bvslt (s1, s2) }
  | LPAREN BVSLE s1=sorted_term s2=sorted_term RPAREN
    { Bvsle (s1, s2) }
  | LPAREN BVSGT s1=sorted_term s2=sorted_term RPAREN
    { Bvsgt (s1, s2) }
  | LPAREN BVSGE s1=sorted_term s2=sorted_term RPAREN
    { Bvsge (s1, s2) }
  | LPAREN SELECT s1=sorted_term s2=sorted_term RPAREN
    { Select (s1, s2) }
  | LPAREN STORE s1=sorted_term s2=sorted_term s3=sorted_term RPAREN
    { Store (s1, s2, s3) }
  | BVBIN
    { Bvbin $1 }
  | BVHEX
    { Bvhex $1 }
  | LPAREN INDEX s=BVDEC l=INT RPAREN
    { let len = (String.length s) in
      let i_num = Numeral.of_string (String.sub s 2 (len-2)) in
      let l_num = Numeral.of_int l in
        Bvbin (bv_dec_to_bin i_num l_num) }
  | LPAREN BVAND args=list(sorted_term) RPAREN
    { (build_tree_left_ass "bvand" args) }
  | LPAREN BVOR args=list(sorted_term) RPAREN
    { (build_tree_left_ass "bvor" args) }
  | LPAREN BVXOR args=list(sorted_term) RPAREN
    { (build_tree_left_ass "bvxor" args) }
  | LPAREN BVNAND s1=sorted_term s2=sorted_term RPAREN
    { Bvnand (s1, s2) }
  | LPAREN BVNOR s1=sorted_term s2=sorted_term RPAREN
    { Bvnor (s1, s2) }
  | LPAREN BVXNOR s1=sorted_term s2=sorted_term RPAREN
    { Bvxnor (s1, s2) }
  | LPAREN BVMUL args=list(sorted_term) RPAREN
    { (build_tree_left_ass "bvmul" args) }
  | LPAREN BVADD args=list(sorted_term) RPAREN
    { (build_tree_left_ass "bvadd" args) }
  | LPAREN BVSUB s1=sorted_term s2=sorted_term RPAREN
    { Bvsub (s1, s2) }
  | LPAREN BVUDIV s1=sorted_term s2=sorted_term RPAREN
    { Bvudiv (s1, s2) }
  | LPAREN BVUREM s1=sorted_term s2=sorted_term RPAREN
    { Bvurem (s1, s2) }
  | LPAREN BVSDIV s1=sorted_term s2=sorted_term RPAREN
    { Bvsdiv (s1, s2) }
  | LPAREN BVSREM s1=sorted_term s2=sorted_term RPAREN
    { Bvsrem (s1, s2) }
  | LPAREN BVSMOD s1=sorted_term s2=sorted_term RPAREN
    { Bvsmod (s1, s2) }
  | LPAREN BVSHL s1=sorted_term s2=sorted_term RPAREN
    { Bvshl (s1, s2) }
  | LPAREN BVLSHR s1=sorted_term s2=sorted_term RPAREN
    { Bvlshr (s1, s2) }
  | LPAREN BVASHR s1=sorted_term s2=sorted_term RPAREN
    { Bvashr (s1, s2) }
  | LPAREN BVCONCAT s1=sorted_term s2=sorted_term RPAREN
    { Bvconcat (s1, s2) }
  | LPAREN BVNEG s=sorted_term RPAREN
    { Bvneg s }
  | LPAREN BVNOT s=sorted_term RPAREN
    { Bvnot s }
  | LPAREN LPAREN INDEX BVEXTRACT i=INT j=INT RPAREN s=sorted_term RPAREN
    { Bvextract (i,j,s) }
  | LPAREN LPAREN INDEX BVZEROEXT i=INT RPAREN s=sorted_term RPAREN
    { Bvzeroext (i,s) }
  | LPAREN LPAREN INDEX BVSIGNEXT i=INT RPAREN s=sorted_term RPAREN
    { Bvsignext (i,s) }
  | LPAREN LPAREN INDEX BVLROTATE i=INT RPAREN s=sorted_term RPAREN
    { Bvlrotate (i,s) }
  | LPAREN LPAREN INDEX BVRROTATE i=INT RPAREN s=sorted_term RPAREN
    { Bvrrotate (i,s) }
  | LPAREN LPAREN INDEX BVREPEAT i=INT RPAREN s=sorted_term RPAREN
    { Bvrepeat (i,s) }
  | LPAREN BVCOMP s1=sorted_term s2=sorted_term RPAREN
    { Bvcomp (s1,s2) }
  | IDENT { Var $1 }
  | LPAREN IDENT actual_args=list(sorted_term) RPAREN
    { match (Hashtbl.find fun_map $2) with
      | (formal_args, body) -> replace formal_args actual_args body
      | exception Not_found -> Appl ($2, actual_args) }
  
;

assertion:
  | LPAREN ASSERT sorted_term RPAREN
    { (concat_sp_sep_2 "assert" (to_string_sorted_term $3)) }
;

args:
  | LPAREN l=list(sort) RPAREN
    { let s = (String.concat " " l) in
      (concat_sp_sep_1 s)}
;

sortedarg:
  | LPAREN IDENT sort RPAREN
    { Var $2 }
;

defargs:
  | LPAREN l=list(sortedarg) RPAREN
    { l }
;

command:
  | LPAREN SETLOGIC IDENT RPAREN 
    { (concat_sp_sep_2 "set-logic" $3) }
  | LPAREN DECLARECONST IDENT sort RPAREN 
    { (concat_sp_sep_3 "declare-const" $3 $4) }
  | LPAREN DECLAREFUN IDENT args sort RPAREN
    { (concat_sp_sep_4 "declare-fun" $3 $4 $5) }
  | LPAREN DECLARESORT IDENT INT RPAREN
    { (concat_sp_sep_3 "declare-sort" $3 (string_of_int $4)) }
  | LPAREN DEFINEFUN IDENT defargs sort sorted_term RPAREN
    { let _ = (Hashtbl.add fun_map $3 ($4,$6)) in 
      "" }
  | LPAREN CHECKSAT RPAREN
    { (concat_sp_sep_1 "checksat") }
  | LPAREN EXIT RPAREN
    { (concat_sp_sep_1 "exit") }
  | assertion
    { $1 }
;

file:
  | l=nonempty_list(command) EOF 
    { let s = ((String.concat "\n" l)^"\n") in
      print_string s }
;