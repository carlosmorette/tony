defmodule Tony.Procedure do
  @enforce_keys [:params, :body]

  defstruct [:name, :params, :body]
end
