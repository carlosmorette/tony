# Tony

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tony` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tony, "~> 0.1.0"}
  ]
end
```

```
(defun (sum a b)
  (+ a b))

(print (sum 9 44))

(defun (checklanguage name)
   (if (== name "Tony")
       "My Own LISP"
       "Another language"))

(print (checklanguage "Tony")) ;; My Own LISP


;; Lambda

(defun (mult-lambda-version a b callback)
    (callback (* a b)))

(mult-lambda-version 2 3 (lambda (r) (print r))) ;; 6

((lambda (x) (print x)) "That's works!") ;; That's works!
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tony](https://hexdocs.pm/tony).

