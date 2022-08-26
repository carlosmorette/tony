defmodule Tony.Environment do
  alias __MODULE__

  alias Tony.Procedure

  @comparators [
    "==",
    "!=",
    ">=",
    "<=",
    ">",
    "<"
  ]

  @logic_operators [
    "and",
    "or",
    "not"
  ]

  @number_operators [
    "+",
    "-",
    "*",
    "/"
  ]

  @list ["list", "head", "tail", "empty?"]

  @procedures [
                "defproc",
                "print",
                "if",
                "lambda",
                "import",
                "cond"
              ] ++ @comparators ++ @logic_operators ++ @number_operators ++ @list

  defstruct curr_scope: %{},
            out_scope: %{},
            available: nil

  def new(), do: %Environment{available: @procedures}

  def get(env, key) do
    value = get(env, :curr_scope, key)

    if is_nil(value) do
      get(env, :out_scope, key)
    else
      value
    end
  end

  def get(env, :curr_scope, key) do
    Map.get(env.curr_scope, key)
  end

  def get(env, :out_scope, key) do
    Map.get(env.out_scope, key)
  end

  def available?(env, id), do: id in env.available

  def available_identifier?(env, id) do
    value = get(env, :curr_scope, id)
    if is_nil(value), do: true, else: false
  end

  def provide(env, procs) do
    %{env | available: env.available ++ procs}
  end

  def put_procedure(env, %Procedure{name: name, params: _params, body: _body} = proc) do
    %{env | curr_scope: Map.put(env.curr_scope, name, proc)}
  end

  def new_scope(env) do
    %{env | out_scope: Map.merge(env.out_scope, env.curr_scope), curr_scope: %{}}
  end

  def put(env, map) do
    %{env | curr_scope: Map.merge(env.curr_scope, map)}
  end
end
