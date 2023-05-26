defmodule Demo.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "hello from #{inspect(Node.self())}.")
  end

  match _ do
    send_resp(conn, 404, "oops, not found.")
  end
end
