(defsystem "lisp_sew"
  :version "0.1.0"
  :author ""
  :license ""
  :depends-on ()
  :components ((:module "src"
                :components
                ((:file "main"))))
  :description ""
  :in-order-to ((test-op (test-op "lisp_sew/tests"))))

(defsystem "lisp_sew/tests"
  :author ""
  :license ""
  :depends-on ("lisp_sew"
               "rove")
  :components ((:module "tests"
                :components
                ((:file "main"))))
  :description "Test system for lisp_sew"
  :perform (test-op (op c) (symbol-call :rove :run c)))
