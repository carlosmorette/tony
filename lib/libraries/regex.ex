defmodule Tony.Libraries.Regex do
  @behaviour Tony.Libraries

  @impl true
  def procedures, do: ["build", "match-pattern?", "run", "split"]

  def build(regex_str) when is_binary(regex_str) do
    Regex.compile(regex_str)
  end

  def build(another), do: raise("#{another}: needs be a string")

  def match_pattern?(re, pattern) do
    check_if_valid_regex_op!(re, pattern)
    Regex.match?(re, pattern)
  end

  def run(re, pattern) do
    check_if_valid_regex_op!(re, pattern)
    Regex.run(re, pattern)
  end

  def split(re, pattern) do
    check_if_valid_regex_op!(re, pattern)
    Regex.split(re, pattern)
  end

  def check_if_valid_regex_op!(re, pattern) do
    if not (Regex.regex?(re) and is_binary(pattern)) do
      raise "#{re}: needs be a valid regex and #{pattern} needs be a string"
    end
  end
end
