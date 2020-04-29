(set-logic QF_BV)
(set-info :smt-lib-version 2.0)
(set-info :category "crafted")
(set-info :status unsat)
(declare-fun v0 () (_ BitVec 4))
(declare-fun v1 () (_ BitVec 4))
(assert (= v0 #b0000))
(assert (= v1 #b1111))
(assert (bvult v0 v1))
(assert (bvule v0 v1))
(assert (bvugt v0 v1))
(assert (bvuge v0 v1))
(assert (bvslt v0 v1))
(assert (bvsle v0 v1))
(assert (bvsgt v0 v1))
(assert (bvsge v0 v1))
(check-sat)
(exit)
