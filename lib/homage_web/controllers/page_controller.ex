defmodule HomageWeb.PageController do
  use HomageWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
