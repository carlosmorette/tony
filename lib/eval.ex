defmodule Tony.Eval do
  alias Tony.{
    Token,
    Expression,
    Environment
  }

  def run({:ok, declarations}) do
    env = Environment.new()
    eval(env, declarations)
  end

  def eval(env, []), do: {env, nil}

  def eval(env, [first | []]) do
    env
    |> eval(first)
    |> elem(1)
  end

  def eval(env, [first | rest]) do
    {env, _result} = eval(env, first)
    eval(env, rest)
  end

  def eval(env, %Expression{identifier: identifier, parameters: params}) do
    {env, id} = eval(env, identifier)

    cond do
      build_in?(env, id) ->
        eval(id, params, env)
    end
  end

  def eval(env, %Token{id: id, value: value}) do
    case id do
      :NUMBER ->
        {env, String.to_integer(value)}

      :STRING ->
        {env, String.replace(value, "\"", "")}

      :BOOLEAN ->
        {env, String.to_atom(value)}

      :IDENTIFIER ->
        if build_in?(env, value) do
          {env, value}
        else
          case Environment.get(env, value) do
            nil -> raise "#{value} not found"
            var -> {env, var}
          end
        end

      :OPERATOR ->
        {env, value}
    end
  end

  def build_in?(env, id), do: id in env.build_in

  def eval(identifier, params, env) do
    {params, env} =
      Enum.map_reduce(params, env, fn p, e ->
        {new_e, result} = eval(e, p)

        {result, new_e}
      end)

    case identifier do
      "+" -> handle_operator("+", params, env)
      "-" -> handle_operator("-", params, env)
      "*" -> handle_operator("*", params, env)
      "/" -> handle_operator("/", params, env)
      "and" -> handle_operator("and", params, env)
      "or" -> handle_operator("or", params, env)
      "not" -> handle_operator("not", params, env)
      "defun" -> handle_defun(params, env)
    end
  end

  def handle_operator("+", params, env) do
    check_if_all_numbers!(params)

    {env, Enum.sum(params)}
  end

  def handle_operator("-", [head | params], env) do
    check_if_all_numbers!(params)

    {env, Enum.reduce(params, head, &(&2 - &1))}
  end

  def handle_operator("*", [head | params], env) do
    check_if_all_numbers!(params)

    {env, Enum.reduce(params, head, &(&2 * &1))}
  end

  def handle_operator("/", [head | params], env) do
    check_if_all_numbers!(params)

    {env, Enum.reduce(params, head, &(&2 / &1))}
  end

  def handle_operator("and", params, env) do
    {env,
     Enum.reduce_while(params, true, fn p, _acc ->
       if p, do: {:cont, true}, else: {:halt, false}
     end)}
  end

  def handle_operator("or", params, env) do
    {env,
     Enum.reduce_while(params, false, fn p, _acc ->
       if p, do: {:halt, true}, else: {:cont, false}
     end)}
  end

  def handle_defun(_params, env), do: {env, nil}

  def check_if_all_numbers!(params) do
    is? = Enum.all?(params, &is_number/1)

    if not is?, do: raise("All needs be a number")
  end
end
