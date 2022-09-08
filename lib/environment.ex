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

  @list ["list", "head", "tail", "empty?", "append", "get-by-index"]

  @procedures [
                "defproc",
                "print",
                "if",
                "lambda",
                "import",
                "cond",
                "map"
              ] ++ @comparators ++ @logic_operators ++ @number_operators ++ @list

  defstruct inner: %{},
            outer: nil,
            available: nil

  def new(%Environment{} = env) do
    %Environment{
      available: env.available,
      outer: env,
      inner: %{}
    }
  end

  def new(), do: %Environment{available: @procedures}

  def get(nil, _key), do: nil

  def get(%Environment{} = env, key) do
    case Map.get(env.inner, key) do
      nil ->
        get(env.outer, key)

      value ->
        value
    end
  end

  def available?(env, id), do: id in env.available

  def available_identifier?(env, id) do
    value = get(env, id)
    if is_nil(value), do: true, else: false
  end

  def provide(env, procs) do
    %{env | available: env.available ++ procs}
  end

  def put_procedure(env, %Procedure{name: name, params: _params, body: _body} = proc) do
    %{env | inner: Map.put(env.inner, name, proc)}
  end

  def new_scope(env) do
    %{env | outer: Map.merge(env.outer || %{}, env.inner), inner: %{}}
  end

  def put(env, map) do
    %{env | inner: Map.merge(env.inner, map)}
  end
end
