(set-logic QF_BV)
;(set-info :smt-lib-version 2.0)
;(set-info :category "crafted")
;(set-info :status unsat)
(declare-fun v0 () (_ BitVec 4))
(declare-fun v1 () (_ BitVec 4))
(declare-fun v2 () (_ BitVec 4))
(declare-fun v3 () (_ BitVec 4))

(assert (= v0 ((_ rotate_right 2)((_ rotate_left 3) #b0001))))
(assert (= v1 ((_ repeat 4)
	         (bvcomp 
		   ((_ extract 1 0) #b0011) 
		   ((_ extract 3 2) #b0011)))))
(assert (= v0 v1))
(assert (= v2 ((_ zero_extend 2) 
	         ((_ extract 1 0) #b0011))))
(assert (= v3 ((_ sign_extend 2) 
	         ((_ extract 1 0) #b1111))))
(assert (= v2 v3))
(check-sat)
(exit)