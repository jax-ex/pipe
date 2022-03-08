# Pipe

Pipe is a Plug clone with minimal features. The intent is to familiarize people
with more advanced Elixir techniques.

# How to approach this project

1. Refresh yourself on macros
2. Read the following explanation
3. Look at the code
4. mix problems:halt
5. mix problems:router

## Intro

What is Plug (or in our case Pipe)? At it's core, it is a group of
convenience's for building web applications. In this code base there is a small
subset of these convenience functions. This code does not focus on adapters,
protocols, files, etc... Instead Pipe focuses on the most fundamental parts of
Plug.

### Pipe

A simple behaviour (interface). It defines two functions, `init/1` and `call/2`. These functions are used to define module middleware.

### Conn

A struct that represents the request and the reponse. In Plug this struct also
represents the adapter and tcp socket.

### Builder

This is the workhorse. This module glues middleware together reducing complexity.

```elixir
defmodule PostController do
  # ... code that apply's show/2 function

  def show(conn, _opts) do
    case authenticate(conn) do
      {:ok, user} ->
        case find_message(params["id"]) do
          nil ->
            conn |> put_flash(:info, "That message wasn't found") |> redirect(to: "/")
          message ->
            case authorize_message(conn, params["id"])
              :ok ->
                render(conn, :show, page: find_page(params["id"]))
              :error ->
                conn |> put_flash(:info, "You can't access that page") |> redirect(to: "/")
            end
        end
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: "/")
    end
  end
end
```

Adding to this code means nesting another case statement. Reordering this code
requires significant change. Builder allows us easily add to and reorder while
also giving a way to abstract code into smaller peices.


```elixir
defmodule PostController do
  use Pipe.Builder

  pipe :authenticate
  pipe :find_message
  pipe :authorize_message
  pipe :show

  def show(conn, _) do
    params = conn.query_params
    render(conn, :show, page: find_page(params["id"]))
  end

  defp authenticate(conn, _) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        assign(conn, :user, user)

      :error ->
        conn
        |> put_flash(:info, "You must be logged in")
        |> redirect(to: "/")
        |> halt()
    end
  end

  defp find_message(conn, _) do
    case find_message(params["id"]) do
      nil ->
        conn
        |> put_flash(:info, "That message wasn't found")
        |> redirect(to: "/")
        |> halt()

      message ->
        assign(conn, :message, message)
    end
  end

  defp authorize_message(conn, _) do
    if Authorizer.can_access?(conn.assigns[:user], conn.assigns[:message]) do
      conn
    else
      conn
      |> put_flash(:info, "You can't access that page")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
```

Notice that if any of these Pipe's fail, `halt/1` is called and the next pipe
in the order is not applied.

This works using Elixir's powerful macro system. The `pipe/1` function is a macro that compiles into:

```elixir
@pipes {:function_or_module_name, []}
```

So the following code:

```elixir
pipe :authenticate
pipe :find_message
pipe :authorize_message
pipe :show
```

becomes:

```elixir
@pipes {:authenticate, []}
@pipes {:find_message, []}
@pipes {:authorize_message, []}
@pipes {:show, []}
```

There is a `__using__/1` macro which is called when `use Pipe.Builder` is
invoked. This special macro defines the the functions that implement the Pipe
behaviour. The important piece is it defines the `call/2` function which
applies it's arguments to the `pipe_builder_call/2` function. Note that
`pipe_builder_call/2` does not exist yet.

```elixir
defmacro __using__(opts) do
  def call(conn, opts) do
    pipe_builder_call(conn, opts)
  end
end
```

After all macro expansion is done the special `__before_compile__/1` macro gets
called. At this time all the `@pipes` have been collected into a list that can
be iterated over. Each one is evaluated to see if it's a module or a function
and then it's compiled into the `pipe_builder_call/2` function.

So our above example compiles to this:

```elixir
def pipe_builder_call(conn, opts) do
  show(authorize_message(find_message(authenticate(conn))))
end
```

### Router

A router is really just a builder. It has it's own `__using__/1` macro that
defines two functions, `match/2` and `dispatch/2` these are intended to be used
as Pipes. Match finds a matching route, then returns a anonymous function that
is set on the conn. Dispatch simply looks up the anonymous function and calls
it.

There are a couple of convenience macros (which are left as a problem) that
create `do_match/2` functions that are applied within the `match/2` pipe.



### Related
Most of my code/inpiration came from looking at an older version of Plug:
https://github.com/elixir-plug/plug/tree/v0.3.0

Here are various blog posts that where borrowed from or used as refreshers:
https://elixir-lang.org/getting-started/meta/domain-specific-languages.html#building-our-own-test-case
https://blog.janfornoff.com/elixir-macros-2/
https://elixirschool.com/en/lessons/advanced/metaprogramming/
https://medium.com/@kansi/elixir-plug-unveiled-bf354e364641
https://codewords.recurse.com/issues/five/building-a-web-framework-from-scratch-in-elixir

### SPECIAL NOTICE:
Plug has no tests for guards, this is a great opportunity to contribute to Plug:
https://github.com/elixir-plug/plug/blob/master/test/plug/builder_test.exs

Phoenix had a bug related to guards being expanded too late:
https://github.com/phoenixframework/phoenix/issues/3688#issuecomment-592933368

Commit where guards were fixed in Phoenix:
https://github.com/phoenixframework/phoenix/commit/2e8c63c01fec4dde5467dbbbf9705ff9e780735e

Plug still uses `Macro.escape/2`, not sure if this means Plug is Bugged
https://github.com/elixir-plug/plug/blob/master/lib/plug/builder.ex#L337-L339
