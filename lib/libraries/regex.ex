defmodule Tony.Libraries.Regex do
  @behaviour Tony.Libraries

  @impl true
  def procedures, do: ["build", "match-pattern?"]

  def build(regex_str) when is_binary(regex_str) do
    Regex.compile(regex_str)
  end

  def build(another), do: raise("#{another}: needs be a string")

  def match_pattern?(re, pattern) when is_binary(pattern) do
    if Regex.regex?(re) do
      Regex.match?(re, pattern)
    else
      raise "#{re}: needs be a valid regex"
    end
  end
end
