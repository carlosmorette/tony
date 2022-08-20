defmodule Tony.Environment do
  alias __MODULE__

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

  @functions [
               "+",
               "-",
               "*",
               "/",
               "defun",
               "print",
               "if",
               "lambda"
             ] ++ @comparators ++ @logic_operators

  defstruct curr_scope: %{},
            out_scope: %{},
            build_in: nil

  def new(), do: %Environment{build_in: @functions}

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

  def built_in?(env, id), do: id in env.build_in

  def available_identifier?(env, id) do
    value = get(env, :curr_scope, id)
    if is_nil(value), do: true, else: false
  end

  def put_fun(env, %{name: name, params: _params, body: _body} = fun) do
    %{env | curr_scope: Map.put(env.curr_scope, name, fun)}
  end

  def new_scope(env) do
    %{env | out_scope: Map.merge(env.out_scope, env.curr_scope), curr_scope: %{}}
  end

  def put(env, map) do
    %{env | curr_scope: Map.merge(env.curr_scope, map)}
  end
end
