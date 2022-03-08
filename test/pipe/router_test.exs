defmodule Pipe.RouterTest do
  use ExUnit.Case, async: true

  defmodule MyBlogRouter do
    use Pipe.Router

    pipe :match
    pipe :dispatch

    def do_match("GET", "/") do
      fn conn ->
        conn
        |> put_status(200)
        |> put_resp_body("<h1>Welcome!</h1>")
      end
    end

    def do_match("POST", "/hello") do
      fn conn ->
        name = conn.query_params[:name] || "World"

        conn
        |> put_status(201)
        |> put_resp_body("<h1>Hello #{name}!</h1>")
      end
    end

    def do_match(_method, _path) do
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
  test "GET /" do
    response = get("/")
    assert response.status == 200
    assert response.resp_body == "<h1>Welcome!</h1>"
  end

  test "POST /hello" do
    response = post("/hello", %{})
    assert response.status == 201
    assert response.resp_body == "<h1>Hello World!</h1>"
  end

  test "POST /hello => Jax.Ex" do
    response = post("/hello", %{name: "Jax.Ex"})
    assert response.status == 201
    assert response.resp_body == "<h1>Hello Jax.Ex!</h1>"
  end

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

    MyBlogRouter.call(conn, MyBlogRouter.init([]))
  end

  def post(path, params) do
    conn = %Pipe.Conn{
      method: "POST",
      path: path,
      query_params: params
    }

    MyBlogRouter.call(conn, MyBlogRouter.init([]))
  end
end
