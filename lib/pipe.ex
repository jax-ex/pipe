defmodule Pipe do
  @type opts ::
          binary
          | tuple
          | atom
          | integer
          | float
          | [opts]
          | %{optional(opts) => opts}
          | MapSet.t()

  @callback init(opts) :: opts
  @callback call(conn :: Pipe.State.t(), opts) :: Pipe.State.t()
end
