defmodule RoutineWeb.PageController do
  use RoutineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
