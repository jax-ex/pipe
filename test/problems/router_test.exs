defmodule Problems.RouterTest do
  @moduledoc """
  *****************************************************************************
  Write the get and post macros for the router
  *****************************************************************************
  """

  use ExUnit.Case, async: true

  defmodule RouterMacros do
    use Pipe.Router

    pipe :match
    pipe :dispatch

    get "/" do
      conn
      |> put_status(200)
      |> put_resp_body("<h1>Welcome!</h1>")
    end

    post "/hello" do
      name = conn.query_params[:name] || "World"

      conn
      |> put_status(201)
      |> put_resp_body("<h1>Hello #{name}!</h1>")
    end

    def do_match(_method, _params) do
      fn conn ->
        conn
        |> put_status(404)
        |> put_resp_body("<h1>Not Found Error</h1>")
      end
    end
  end

  ##
  # Tests
  #
  @tag router_problem: true
  test "GET /" do
    response = get("/")
    assert response.status == 200
    assert response.resp_body == "<h1>Welcome!</h1>"
  end

  @tag router_problem: true
  test "POST /hello" do
    response = post("/hello", %{})
    assert response.status == 201
    assert response.resp_body == "<h1>Hello World!</h1>"
  end

  @tag router_problem: true
  test "POST /hello => Jax.Ex" do
    response = post("/hello", %{name: "Jax.Ex"})
    assert response.status == 201
    assert response.resp_body == "<h1>Hello Jax.Ex!</h1>"
  end

  @tag router_problem: true
  test "404 error for anything else" do
    response = get("/nope")
    assert response.status == 404
    assert response.resp_body == "<h1>Not Found Error</h1>"
  end

  ##
  # Helpers
  #
  def get(path) do
    conn = %Pipe.Conn{
      method: "GET",
      path: path
    }

    RouterMacros.call(conn, RouterMacros.init([]))
  end

  def post(path, params) do
    conn = %Pipe.Conn{
      method: "POST",
      path: path,
      query_params: params
    }

    RouterMacros.call(conn, RouterMacros.init([]))
  end
end
