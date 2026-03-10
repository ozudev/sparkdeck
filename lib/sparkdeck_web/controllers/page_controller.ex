defmodule SparkdeckWeb.PageController do
  use SparkdeckWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
