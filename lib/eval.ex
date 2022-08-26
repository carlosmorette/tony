defmodule Tony.Eval do
  alias Tony.{
    Token,
    Libraries,
    Procedure,
    Expression,
    Environment
  }

  def run(declarations, %Environment{} = env) do
    eval(env, declarations)
  end

  def eval(env, [first | []]) do
    eval(env, first)
  end

  def eval(env, [first | rest]) do
    {env, _result} = eval(env, first)
    eval(env, rest)
  end

  def eval(env, %Expression{identifier: nil}), do: {env, nil}

  def eval(env, %Expression{identifier: identifier, parameters: params}) do
    {env, id} = eval(env, identifier)

    if Environment.available?(env, id) do
      eval(id, params, env)
    else
      eval_procedure_call(id, params, env)
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
        case Environment.get(env, value) do
          nil ->
            if Environment.available?(env, value) do
              {env, value}
            else
              raise "#{value} not found"
            end

          id ->
            {env, id}
        end

      :OPERATOR ->
        {env, value}

      :COMPARATOR ->
        {env, value}

      :LOGIC_OPERATOR ->
        {env, value}
    end
  end

  def eval("defproc", [_ | []], _env), do: raise("defproc: expects a body")

  def eval("defproc", [%Expression{identifier: id, parameters: params} | body], env) do
    procedure = %Procedure{
      name: id.value,
      params: Enum.map(params, fn p -> p.value end),
      body: body
    }

    {Environment.put_procedure(env, procedure), nil}
  end

  def eval("not", [param | []], env) do
    {env, param} = eval(env, param)

    {env, !param}
  end

  def eval("print", [param | []], env) do
    {env, result} = eval(env, param)
    IO.puts(inspect(result))
    {env, result}
  end

  def eval("lambda", [params, body], env) do
    {env, %Procedure{params: Enum.map(params, fn t -> t.value end), body: body}}
  end

  def eval("list", params, env) do
    {env, items} = eval_all(env, params)
    {env, items}
  end

  def eval("head", [param | []], env) do
    {env, result} = eval(env, param)
    {env, List.first(result)}
  end

  def eval("tail", [param | []], env) do
    {env, result} = eval(env, param)

    if Enum.empty?(result) do
      {env, []}
    else
      [_head | tail] = result
      {env, tail}
    end
  end

  def eval("empty?", [param | []], env) do
    {env, result} = eval(env, param)
    {env, Enum.empty?(result)}
  end

  def eval("append", [left, right | []], env) do
    {env, [left, right]} = eval_all(env, [left, right])

    if is_list(left) and is_list(right) do
      {env, left ++ right}
    else
      raise "append: arguents needs be a list"
    end
  end

  def eval("append", _params, _env), do: raise("append: expects 2 arguments")

  def eval(procedure, _params, _env)
      when procedure in ["head", "tail", "empty?", "print", "not"] do
    raise "#{procedure}: expects 1 argument"
  end

  def eval("get-by-index", [list, index | []], env) do
    {env, [list, index]} = eval_all(env, [list, index])
    {env, Enum.at(list, index)}
  end

  def eval("if", [condition, true_expr, false_expr], env) do
    {env, condition} = eval(env, condition)

    if true?(condition) do
      eval(env, true_expr)
    else
      eval(env, false_expr)
    end
  end

  def eval("file:read", [path | []], env) do
    {env, path} = eval(env, path)

    case Libraries.File.read(path) do
      {:ok, content} -> {env, content}
      {:error, error} -> {env, to_string(error)}
    end
  end

  def eval("file:read", _params, _env), do: raise("file:read: expects 1 argument")

  def eval("file:write", [path, content | []], env) do
    {env, path} = eval(env, path)
    {env, content} = eval(env, content)

    case Libraries.File.write(path, content) do
      :ok -> {env, content}
      {:error, error} -> {env, to_string(error)}
    end
  end

  def eval("file:write", _params, _env), do: raise("file:write: expects 2 arguments")

  def eval("regex:build", [param | []], env) do
    {env, regex_str} = eval(env, param)

    result =
      case Libraries.Regex.build(regex_str) do
        {:ok, regex} -> regex
        {:error, error} -> inspect(error)
      end

    {env, result}
  end

  def eval("regex:match-pattern?", [re, pattern | []], env) do
    {env, [re, pattern]} = eval_all(env, [re, pattern])
    {env, Libraries.Regex.match_pattern?(re, pattern)}
  end

  def eval("regex:run", [re, pattern | []], env) do
    {env, [re, pattern]} = eval_all(env, [re, pattern])
    {env, Libraries.Regex.run(re, pattern)}
  end

  def eval("regex:split", [re, pattern | []], env) do
    {env, [re, pattern]} = eval_all(env, [re, pattern])
    {env, Libraries.Regex.split(re, pattern)}
  end

  def eval("cond", params, env) do
    params
    |> Enum.reduce_while({env, false}, fn expr, {aenv, sometrue?} ->
      {nenv, r} = eval(aenv, expr.identifier)

      if true?(r), do: {:halt, {nenv, expr}}, else: {:cont, {nenv, sometrue?}}
    end)
    |> case do
      {_, false} ->
        raise "cond: no true expression"

      {env, expr} ->
        eval_cond_body(env, expr)
    end
  end

  def eval("+", params, env) do
    {env, params} = eval_all(env, params)
    check_if_all_numbers!(params)
    {env, Enum.sum(params)}
  end

  def eval("-", params, env) do
    {env, params} = eval_all(env, params)
    check_if_all_numbers!(params)
    [head | params] = params
    {env, Enum.reduce(params, head, &(&2 - &1))}
  end

  def eval("*", params, env) do
    {env, params} = eval_all(env, params)
    check_if_all_numbers!(params)
    [head | params] = params
    {env, Enum.reduce(params, head, &(&2 * &1))}
  end

  def eval("/", params, env) do
    {env, params} = eval_all(env, params)
    check_if_all_numbers!(params)
    [head | params] = params
    {env, Enum.reduce(params, head, &(&2 / &1))}
  end

  def eval("and", params, env) do
    {env, params} = eval_all(env, params)

    {env,
     Enum.reduce_while(params, true, fn p, _acc ->
       if p, do: {:cont, true}, else: {:halt, false}
     end)}
  end

  def eval("or", params, env) do
    {env, params} = eval_all(env, params)

    {env,
     Enum.reduce_while(params, false, fn p, _acc ->
       if p, do: {:halt, true}, else: {:cont, false}
     end)}
  end

  def eval(comparator, [left, right | []], env)
      when comparator in ["==", "!=", ">=", "<=", ">", "<"] do
    {env, [left, right]} = eval_all(env, [left, right])

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

  def eval(proc, _params, _env) when proc in ["==", "!=", ">=", "<=", ">", "<"],
    do: raise("#{proc}: expects 2 arguments")

  def eval("import", params, env) do
    {env, lib_names} = eval_all(env, params)

    case Libraries.check_if_all_exist(lib_names) do
      :ok ->
        procedures =
          lib_names
          |> Libraries.build_procedures_with_lib_name()
          |> List.flatten()

        {Environment.provide(env, procedures), nil}

      {:error, {:not_found, lib_name}} ->
        raise "#{lib_name}: librarie not found"
    end
  end

  def eval_procedure_call(%Procedure{} = procedure, params, env) do
    {env, params} = eval_all(env, params)

    params =
      procedure.params
      |> Enum.zip(params)
      |> Enum.into(%{})

    env =
      env
      |> Environment.new_scope()
      |> Environment.put(params)

    do_eval_procedure_body(env, procedure.body)
  end

  def do_eval_procedure_body(env, [last | []]), do: eval(env, last)

  def do_eval_procedure_body(env, [first | rest]) do
    {env, _result} = eval(env, first)

    do_eval_procedure_body(env, rest)
  end

  def eval_cond_body(env, %Expression{parameters: cond_body}) do
    do_eval_procedure_body(env, cond_body)
  end

  def do_eval_cond_body(env, [last | []]), do: eval(env, last)

  def do_eval_cond_body(env, [first | rest]) do
    {env, _result} = eval(env, first)
    do_eval_procedure_body(env, rest)
  end

  # Utils

  def true?(:null), do: false

  def true?(condition), do: condition

  def check_if_all_numbers!(params) do
    is? = Enum.all?(params, &is_number/1)

    if not is?, do: raise("all needs be a number")
  end

  def eval_all(%Environment{} = env, params) do
    {params, env} =
      Enum.map_reduce(params, env, fn p, e ->
        {new_e, result} = eval(e, p)

        {result, new_e}
      end)

    {env, params}
  end
end
