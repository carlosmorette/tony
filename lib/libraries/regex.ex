defmodule Tony.Libraries.Regex do
  @behaviour Tony.Libraries

  @impl true
  def procedures, do: ["build", "match-pattern?", "run"]

  def build(regex_str) when is_binary(regex_str) do
    Regex.compile(regex_str)
  end

  def build(another), do: raise("#{another}: needs be a string")

  def match_pattern?(re, pattern) do
    if Regex.regex?(re) and is_binary(pattern) do
      Regex.match?(re, pattern)
    else
      raise "#{re}: needs be a valid regex and #{pattern} needs be a string"
    end
  end

  def run(re, pattern) do
    if Regex.regex?(re) and is_binary(pattern) do
      Regex.run(re, pattern)
    else
      raise "#{re}: needs be a valid regex and #{pattern} needs be a string"
    end
  end
end
