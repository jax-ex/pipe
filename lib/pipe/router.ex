defmodule Pipe.Router do
  defmacro __using__(_opts) do
    quote do
      import Pipe.Router

      use Pipe.Builder, only: [pipe: 1, pipe: 2]

      def match(conn, _opts) do
        Pipe.Conn.assign(
          conn,
          :plug_route,
          do_match(conn.method, conn.path)
        )
      end

      def dispatch(%Pipe.Conn{assigns: assigns} = conn, _opts) do
        conn.assigns.plug_route.(conn)
      end

      defoverridable match: 2, dispatch: 2
    end
  end

  # implment solution here
  defmacro get(path, do: block) do
  end

  # implement solution here
  defmacro post(path, do: block) do
  end
end
