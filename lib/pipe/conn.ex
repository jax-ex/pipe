defmodule Pipe.Conn do
  @moduledoc """
  Pipe.Conn is a struct that represents the conn of the current request plus
  convenience methods
  """

  @type assigns :: %{optional(atom) => any}
  @type body :: iodata
  @type headers :: [{binary, binary}]
  @type int_status :: non_neg_integer | nil
  @type method :: binary

  @type t :: %__MODULE__{
          assigns: assigns,
          method: method,
          req_headers: headers,
          path: binary,
          resp_body: body | nil,
          resp_headers: headers,
          status: int_status
        }

  defstruct assigns: %{},
            method: "GET",
            path: "",
            query_params: %{},
            req_headers: %{},
            resp_body: nil,
            resp_content_type: "text/html",
            resp_headers: %{},
            status: nil

  alias __MODULE__

  @doc """
  Convience method to create a new Pipe.Conn
  """
  def new() do
    %Pipe.Conn{}
  end

  @doc """
  Sets the http response status
  ## Examples
      iex> Pipe.Conn.put_status(Pipe.Conn.new(), 200)
      %Pipe.Conn{status: 200}
  """
  def put_status(%Conn{} = conn, status) do
    %{conn | status: status}
  end

  @doc """
  Sets the http response body
  ## Examples
      iex> Pipe.Conn.put_resp_body(Pipe.Conn.new(), "<div>Hello!</div>")
      %Pipe.Conn{resp_body: "<div>Hello!</div>"}
  """
  def put_resp_body(%Conn{} = conn, body) do
    %{conn | resp_body: body}
  end

  @doc """
  Sets the request method
  ## Examples
      iex> Pipe.Conn.put_method(Pipe.Conn.new(), "POST")
      %Pipe.Conn{method: "POST"}
  """
  def put_method(%Conn{} = conn, method) do
    %{conn | method: method}
  end

  @doc """
  Add a http request header
  ## Examples
      iex> conn = Pipe.Conn.put_req_header(Pipe.Conn.new(), "foo", "bar")
      %Pipe.Conn{req_headers: %{"foo" => "bar"}}
      iex> Pipe.Conn.put_req_header(conn, "qux", "que")
      %Pipe.Conn{req_headers: %{"foo" => "bar", "qux" => "que"}}
  """
  def put_req_header(%Conn{} = conn, key, value) do
    req_headers = Map.put(conn.req_headers, key, value)
    %{conn | req_headers: req_headers}
  end

  @doc """
  Sets the request path
  ## Examples
      iex> Pipe.Conn.put_path(Pipe.Conn.new(), "/path")
      %Pipe.Conn{path: "/path"}
  """
  def put_path(%Conn{} = conn, path) do
    %{conn | path: path}
  end

  @doc """
  Add a http response header
  ## Examples
      iex> conn = Pipe.Conn.put_resp_header(Pipe.Conn.new(), "foo", "bar")
      %Pipe.Conn{resp_headers: %{"foo" => "bar"}}
      iex> Pipe.Conn.put_resp_header(conn, "qux", "que")
      %Pipe.Conn{resp_headers: %{"foo" => "bar", "qux" => "que"}}
  """
  def put_resp_header(%Conn{} = conn, key, value) do
    resp_headers = Map.put(conn.resp_headers, key, value)
    %{conn | resp_headers: resp_headers}
  end

  @doc """
  Assigns a value to a key in the connection.
  The "assigns" storage is meant to be used to store values in the connection
  so that other plugs in your plug pipeline can access them. The assigns storage
  is a map.
  ## Examples
      iex> conn = Pipe.Conn.new()
      iex> conn.assigns[:hello]
      nil
      iex> conn = Pipe.Conn.assign(conn, :hello, :world)
      iex> conn.assigns[:hello]
      :world
  """
  def assign(%Conn{assigns: assigns} = conn, key, value) when is_atom(key) do
    %{conn | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Tells the conn builder chain to stop chaining
  """
  def halt(conn), do: conn
end
