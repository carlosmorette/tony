defmodule Tony.Libraries do
  @type procedure :: String.t()

  @callback procedures() :: list(procedure())

  @libs ["file", "regex"]

  def list_all do
    @libs
  end

  def exist?(name), do: name in @libs

  def procedures_by_name(name) do
    case name do
      "file" -> Tony.Libraries.File.procedures()
      "regex" -> Tony.Libraries.Regex.procedures()
    end
  end

  def build_procedures_with_lib_name(lib_names) do
    Enum.map(lib_names, fn ln ->
      procedure_with_lib(ln, procedures_by_name(ln))
    end)
  end

  def procedure_with_lib(lib_name, procedures) do
    Enum.map(procedures, fn p -> "#{lib_name}:#{p}" end)
  end

  def check_if_all_exist([]), do: :ok

  def check_if_all_exist([lib_name | rest]) do
    if exist?(lib_name) do
      check_if_all_exist(rest)
    else
      {:error, {:not_found, lib_name}}
    end
  end
end
