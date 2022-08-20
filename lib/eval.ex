defmodule Tony.Eval do
  alias Tony.{
    Token,
    Procedure,
    Expression,
    Environment
  }

  def run({:ok, declarations}) do
    env = Environment.new()
    eval(env, declarations)

    :ok
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

  def eval(env, %Expression{identifier: nil}), do: {env, nil}

  def eval(env, %Expression{identifier: identifier, parameters: params}) do
    {env, id} = eval(env, identifier)

    cond do
      Environment.built_in?(env, id) ->
        eval(id, params, env)

      true ->
        eval_fun_call(env, id, params)
    end
  end

  def eval(env, %Token{id: id, value: value}) do
    case id do
      :NUMBER ->
        {env, String.to_integer(value)}

      :STRING ->
        {env, String.trim(String.replace(value, "\"", ""))}

      :BOOLEAN ->
        {env, String.to_atom(value)}

      :NULL ->
        {env, :null}

      :IDENTIFIER ->
        if Environment.built_in?(env, value) do
          {env, value}
        else
          case Environment.get(env, value) do
            nil -> raise "#{value} not found"
            var -> {env, var}
          end
        end

      :OPERATOR ->
        {env, value}

      :COMPARATOR ->
        {env, value}

      :LOGIC_OPERATOR ->
        {env, value}
    end
  end

  def eval("defun", [_ | []], _env), do: raise("defun: expects a body")

  def eval("defun", [%Expression{identifier: id, parameters: params} | body], env) do
    procedure = %Procedure{
      name: id.value,
      params: Enum.map(params, fn p -> p.value end),
      body: body
    }

    {Environment.put_fun(env, procedure), nil}
  end

  def eval("not", [param | []], env) do
    {env, param} = eval(env, param)

    {env, !param}
  end

  def eval("print", [param | []], env) do
    {env, result} = eval(env, param)
    IO.inspect(result)
    {env, param}
  end

  def eval("lambda", [params, body], env) do
    {env, %Procedure{params: Enum.map(params, fn t -> t.value end), body: body}}
  end

  def eval("list", params, env) do
    {items, env} =
      Enum.map_reduce(params, env, fn p, e ->
        {new_e, r} = eval(e, p)
        {r, new_e}
      end)

    {env, items}
  end

  def eval("head", [param | []], env) do
    {env, result} = eval(env, param)

    if is_list(result) do
      {env, List.first(result)}
    else
      raise "head: expects a list"
    end
  end

  def eval("tail", [param | []], env) do
    {env, result} = eval(env, param)

    if is_list(result) do
      if Enum.empty?(result) do
        {env, []}
      else
        [_head | tail] = result
        {env, tail}
      end
    else
      raise "tail: expects a list"
    end
  end

  def eval("empty?", [param | []], env) do
    {env, result} = eval(env, param)
    {env, Enum.empty?(result)}
  end

  def eval(fun, _params, _env) when fun in ["head", "tail", "empty?", "print", "not"] do
    raise "#{fun}: expects 1 argument"
  end

  def eval("if", [condition, true_expr, false_expr], env) do
    {env, condition} = eval(env, condition)

    if true?(condition) do
      eval(env, true_expr)
    else
      eval(env, false_expr)
    end
  end

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
      "==" -> handle_comparator("==", params, env)
      "!=" -> handle_comparator("!=", params, env)
      ">=" -> handle_comparator(">=", params, env)
      "<=" -> handle_comparator("<=", params, env)
      ">" -> handle_comparator(">", params, env)
      "<" -> handle_comparator("<", params, env)
    end
  end

  def eval_fun_call(env, %Procedure{} = fun, params) do
    {params, env} =
      Enum.map_reduce(params, env, fn p, acc_env ->
        {env, r} = eval(acc_env, p)
        {r, env}
      end)

    params =
      fun.params
      |> Enum.zip(params)
      |> Enum.into(%{})

    env =
      env
      |> Environment.new_scope()
      |> Environment.put(params)

    do_eval_fun_body(env, fun.body)
  end

  def do_eval_fun_body(env, [last | []]), do: eval(env, last)

  def do_eval_fun_body(env, [first | rest]) do
    {env, _result} = eval(env, first)

    do_eval_fun_body(env, rest)
  end

  def make_head_defun(%Expression{identifier: id, parameters: params}) do
    %{
      name: id.value,
      params: Enum.map(params, fn p -> p.value end)
    }
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

  def handle_comparator(comparator, [left, right | []], env) do
    result =
      case comparator do
        "==" -> left == right
        "!=" -> left != right
        ">=" -> left >= right
        "<=" -> left <= right
        ">" -> left > right
        "<" -> left < right
      end

    {env, result}
  end

  def handle_comparator(comparator, _params, _env),
    do: raise("#{comparator}: expects 2 arguments")

  def true?(:null), do: false

  def true?(condition), do: condition

  def check_if_all_numbers!(params) do
    is? = Enum.all?(params, &is_number/1)

    if not is?, do: raise("All needs be a number")
  end
end
