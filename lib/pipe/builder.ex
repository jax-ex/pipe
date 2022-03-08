defmodule Pipe.Builder do
  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Pipe

      def init(opts) do
        opts
      end

      def call(conn, opts) do
        pipe_builder_call(conn, opts)
      end

      defoverridable Pipe

      import Pipe.Conn
      import Pipe.Builder, only: [pipe: 1, pipe: 2]

      Module.register_attribute(__MODULE__, :pipes, accumulate: true)
      @before_compile Pipe.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    pipes = Module.get_attribute(env.module, :pipes)
    {conn, body} = Pipe.Builder.compile(pipes)

    quote do
      def pipe_builder_call(unquote(conn), opts), do: unquote(body)
    end
  end

  @doc """
  A macro that stores a new pipe.
  """
  defmacro pipe(pipe, opts \\ []) do
    quote do
      @pipes {unquote(pipe), unquote(opts)}
    end
  end

  @doc """
  Compiles a pipe stack.
  It expects a reversed stack (with the last pipe coming first)
  and returns a tuple containing the reference to the connection
  as first argument and the compiled quote stack.
  """
  @spec compile([{Pipe.t(), Pipe.opts()}]) :: {Macro.t(), Macro.t()}
  def compile(stack) do
    conn = quote do: conn
    {conn, Enum.reduce(stack, conn, &quote_pipe(init_pipe(&1), &2))}
  end

  defp init_pipe({pipe, opts}) do
    case Atom.to_charlist(pipe) do
      ~c"Elixir." ++ _ -> init_module_pipe(pipe, opts)
      _ -> init_fun_pipe(pipe, opts)
    end
  end

  defp init_module_pipe(pipe, opts) do
    # compile time
    opts = pipe.init(opts)

    if function_exported?(pipe, :call, 2) do
      {:module, pipe, opts}
    else
      raise ArgumentError,
        message: "#{inspect(pipe)} pipe must implement call/2"
    end
  end

  defp init_fun_pipe(pipe, opts) do
    {:function, pipe, opts}
  end

  defp quote_pipe({:module, pipe, opts}, acc) do
    quote do
      case unquote(pipe).call(conn, unquote(Macro.escape(opts))) do
        %Pipe.Conn{} = conn -> unquote(acc)
        _ -> raise "expected #{unquote(inspect(pipe))}.call/2 to return a Pipe.Conn"
      end
    end
  end

  defp quote_pipe({:function, pipe, opts}, acc) do
    quote do
      case unquote(pipe)(conn, unquote(Macro.escape(opts))) do
        %Pipe.Conn{} = conn -> unquote(acc)
        _ -> raise "expected #{unquote(pipe)}/2 to return a Pipe.Conn"
      end
    end
  end
end
