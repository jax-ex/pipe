defmodule Pipe.BuilderTest do
  use ExUnit.Case, async: true
  import Pipe.Conn

  alias Pipe.Conn

  defmodule Module do
    def init(val) do
      {:init, val}
    end

    def call(conn, opts) do
      stack = [{:call, opts} | conn.assigns[:stack]]
      assign(conn, :stack, stack)
    end
  end

  defmodule Sample do
    use Pipe.Builder

    pipe(:fun)
    pipe(Module, :opts)

    def fun(conn, opts) do
      stack = [{:fun, opts} | conn.assigns[:stack]]
      assign(conn, :stack, stack)
    end
  end

  test "exports the init/1 function" do
    assert Sample.init(:ok) == :ok
  end

  test "builds plug stack in the order" do
    conn = Conn.new() |> assign(:stack, [])

    assert Sample.call(conn, []).assigns[:stack] ==
             [call: {:init, :opts}, fun: []]
  end
end
