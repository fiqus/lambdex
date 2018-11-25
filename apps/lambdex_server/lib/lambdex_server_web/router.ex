defmodule LambdexServerWeb.Router do
  use LambdexServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug(LambdexServer.Auth.AuthAccessPipeline)
  end

  scope "/api", LambdexServerWeb do
    pipe_through :api

    resources "/users", UserController
    post("/users/token", UserController, :token)

    scope "/" do
      pipe_through :auth

      resources "/lambdas", LambdaController
      get "/lambdas/:id/executions", LambdaExecutionController, :get_lambda_executions
      resources "/lambda_executions", LambdaExecutionController
      post "/lambdas/:path", LambdaExecutionController, :run_lambda

    end
  end

  scope "/", LambdexServerWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
