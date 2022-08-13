defmodule Tony.Parser do
  alias __MODULE__

  alias Tony.{Expression, Token}

  defstruct curr: nil, prev: nil, rest: []

  defp expect(%Parser{curr: nil}, expected_id) do
    raise "Expected: #{expected_id}, Got: nil"
  end

  defp expect(%Parser{curr: %Token{id: id}} = p, expected_id) do
    if id == expected_id do
      next_token(p)
    else
      raise "Expected: #{expected_id}, Got: #{id}"
    end
  end

  def get_prev_token(%Parser{prev: token}), do: token

  defp get_curr_token(%Parser{curr: curr} = p) do
    {next_token(p), curr}
  end

  defp expect_and_get(%Parser{curr: %Token{id: id, value: value}} = p, expected_id) do
    if id == expected_id do
      {next_token(p), value}
    else
      raise "Expected: #{expected_id}, Got: #{id}"
    end
  end

  defp next_token(%Parser{curr: curr, rest: []} = p) do
    %{p | prev: curr, rest: [], curr: nil}
  end

  defp next_token(%Parser{curr: curr, prev: _prev, rest: [head | tail]} = p) do
    %{p | prev: curr, rest: tail, curr: head}
  end

  defp from_tokens([]), do: %Parser{}

  defp from_tokens([first | rest]) do
    %Parser{curr: first, rest: rest, prev: nil}
  end

  def match(%Parser{curr: %Token{id: expected}}, expected), do: true

  def match(_parser, _expected), do: false

  def run(tokens) do
    tokens
    |> from_tokens()
    |> parse()
  end

  def parse(p), do: do_parse(p, [])

  def do_parse(%Parser{curr: nil, rest: []}, acc), do: {:ok, acc}

  def do_parse(p, acc) do
    {p, result} = parse_declaration(p)
    do_parse(p, acc ++ [result])
  end

  def parse_declaration(p) do
    cond do
      match(p, :LEFT_PAREN) ->
        parse_expression(p)

      true ->
        parse_primary(p)
    end
  end

  def parse_expression(p) do
    p = expect(p, :LEFT_PAREN)
    {p, id} = expect_and_get(p, :IDENTIFIER)
    {p, value} = parse_parameters(p)
    p = expect(p, :RIGHT_PAREN)

    {p, %Expression{identifier: id, parameters: value}}
  end

  def parse_parameters(p), do: parse_parameters(p, [])

  def parse_parameters(p, params) do
    {p, result} = parse_parameter(p)

    if is_nil(result) do
      {p, params}
    else
      parse_parameters(p, params ++ [result])
    end
  end

  def parse_parameter(p) do
    cond do
      match(p, :LEFT_PAREN) ->
	parse_expression(p)

      match(p, :RIGHT_PAREN) ->
        {p, nil}

      true ->
        parse_primary(p)
    end
  end

  def parse_primary(p) do
    is_primary? =
      match(p, :STRING)
      |> Kernel.or(match(p, :NUMBER))
      |> Kernel.or(match(p, :BOOLEAN))
      |> Kernel.or(match(p, :IDENTIFIER))

    if is_primary? do
      {p, value} = get_curr_token(p)

      {p, value}
    else
      raise "Something is wrong!\n\n #{inspect(p)}"
    end
  end
end
