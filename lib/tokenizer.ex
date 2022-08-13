defmodule Tony.Tokenizer do
  alias Tony.Token

  @rules [
    %{regex: ~r/^\(/, id: :LEFT_PAREN},
    %{regex: ~r/^\)/, id: :RIGHT_PAREN},
    %{regex: ~r/^(true|false)/, id: :BOOLEAN, value?: true},
    %{regex: ~r/^[a-z]+/, id: :IDENTIFIER, value?: true},
    %{regex: ~r/^\".*\"/, id: :STRING, value?: true},
    %{regex: ~r/^\d+/, id: :NUMBER, value?: true},
    %{regex: ~r/^nil/, id: :NIL},
    %{regex: ~r/^\s/, ignore?: true},
    %{regex: ~r/^\n/, ignore?: true},
    %{regex: ~r/^(\+|-|\/|\*)/, id: :OPERATOR, value?: true},
    %{regex: ~r/^(>|<|>=|<=|!=|==)/, id: :COMPARATOR, value?: true},
    %{regex: ~r/^(and|not|or)/, id: :LOGIC_OPERATOR, value?: true}
  ]

  def run(string) do
    tokenize(string)
  end

  def tokenize(input) do
    do_tokenize(input, @rules, [])
  end

  def do_tokenize("", _rules, tokens), do: tokens

  def do_tokenize(input, rules, tokens) do
    rule = get_rule(rules, input)

    cond do
      no_rule?(rule) ->
        raise "Invalid input (tokenizer)\n\n input: #{input}"

      ignore?(rule) ->
        do_tokenize(rest(rule, input), rules, tokens)

      value?(rule) ->
        do_tokenize(
          rest(rule, input),
          rules,
          tokens ++ [%Token{id: rule[:id], value: get_value(rule, input)}]
        )

      true ->
        do_tokenize(
          rest(rule, input),
          rules,
          tokens ++ [%Token{id: rule[:id]}]
        )
    end
  end

  # === utils

  def get_rule(rules, input) do
    Enum.reduce_while(rules, %{}, fn r, acc ->
      if Regex.match?(r[:regex], input) do
        {:halt, r}
      else
        {:cont, acc}
      end
    end)
  end

  def no_rule?(rule) when rule == %{}, do: true

  def no_rule?(_rule), do: false

  def ignore?(%{ignore?: true}), do: true

  def ignore?(_rule), do: false

  def value?(%{value?: true}), do: true

  def value?(_rule), do: false

  def rest(%{regex: regex}, input) do
    regex
    |> Regex.split(input)
    |> Enum.at(1)
  end

  def get_value(%{regex: regex}, input) do
    regex
    |> Regex.run(input)
    |> Enum.at(0)
  end
end
