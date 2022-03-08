defmodule Pipe.HaltTest do
  @moduledoc """
  *****************************************************************************
  Write complete the halt function in the Conn module.
  Modify the macro that creates pipe_builder_call/2 in Builder.
  The modified macro should not call the next Pipe.
  *****************************************************************************
  """

  use ExUnit.Case, async: true
  import Pipe.Conn

  alias Pipe.Conn

  defmodule Halter do
    use Pipe.Builder

    pipe :step, :first
    pipe :step, :second
    pipe :authorize
    pipe :step, :end_of_chain_reached

    def step(conn, step), do: assign(conn, step, true)

    def authorize(conn, _) do
      conn
      |> assign(:authorize_reached, true)
      |> halt()
    end
  end

  @tag halt_problem: true
  test "halt/2 halts the plug stack" do
    conn = Halter.call(Conn.new(), [])
    assert conn.assigns[:first]
    assert conn.assigns[:second]
    assert conn.assigns[:authorize_reached]
    refute conn.assigns[:end_of_chain_reached]
  end
end
