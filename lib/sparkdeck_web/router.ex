defmodule SparkdeckWeb.Router do
  use SparkdeckWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SparkdeckWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SparkdeckWeb do
    pipe_through :browser

    live "/", ProjectLive.Index, :index
    live "/preview", ProjectLive.Preview, :preview
    live "/projects", ProjectLive.Library, :library
    live "/projects/:id/loading", ProjectLive.Loading, :loading
    live "/projects/:id", ProjectLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", SparkdeckWeb do
  #   pipe_through :api
  # end
end
