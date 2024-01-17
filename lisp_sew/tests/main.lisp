(defpackage lisp_sew/tests/main
  (:use :cl
        :lisp_sew
        :rove))
(in-package :lisp_sew/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :lisp_sew)' in your Lisp.

(deftest test-target-1
  (testing "should (= 1 1) to be true"
    (ok (= 1 1))))
