defmodule LambdexServer.Lambdas do
  @moduledoc """
  The Lambdas context.
  """

  import Ecto.Query, warn: false
  alias LambdexServer.Repo

  alias LambdexServer.Lambdas.Lambda

  @doc """
  Returns the list of lambdas for a given user ID.

  ## Examples

      iex> list_lambdas(user.id)
      [%Lambda{}, ...]

  """
  def list_lambdas(user_id) do
    query = from(l in Lambda, where: [user_id: ^user_id], order_by: [desc: l.inserted_at])
    Repo.all(query)
    |> Enum.map(fn lambda -> add_execution_data(lambda) end)
  end

  defp add_execution_data(lambda) do
    {:ok, id} = Ecto.UUID.dump(lambda.id)
    {:ok, executions} = Repo.query("""
    SELECT  to_timestamp(floor((extract('epoch' from date) / 300)) * 300) interval_alias1,
    coalesce(data.c, 0)
    from generate_series(now() - interval '1 hour', now(), '5 minutes'::interval) date
    left outer join (SELECT count(*) c,
                    to_timestamp(floor((extract('epoch' from inserted_at) / 300)) * 300) as interval_alias
             FROM lambda_executions
             where data->>'status' != 'error'
                   AND lambda_id = $1
             GROUP BY interval_alias) as data on data.interval_alias = to_timestamp(floor((extract('epoch' from date) / 300)) * 300)
        """, [id])
    {:ok, durations} = Repo.query("""
    SELECT  to_timestamp(floor((extract('epoch' from date) / 300)) * 300) interval_alias1,
            coalesce(data.c, 0)
    from generate_series(now() - interval '1 hour', now(), '5 minutes'::interval) date
    left outer join (SELECT sum((data->>'duration')::float) c,
                            to_timestamp(floor((extract('epoch' from inserted_at) / 300)) * 300) as interval_alias
                     FROM lambda_executions
                     WHERE data->>'status' != 'error'
                           AND lambda_id = $1
                     GROUP BY interval_alias) as data on data.interval_alias = to_timestamp(floor((extract('epoch' from date) / 300)) * 300)
    """, [id])

    lambda
      |> Map.put(:executions, Enum.map(executions.rows, fn [timestamp, count] -> %{count: count, timestamp: timestamp} end))
      |> Map.put(:durations, Enum.map(durations.rows, fn [timestamp, duration] -> %{duration: duration, timestamp: timestamp} end))

  end

  @doc """
  Gets a single lambda.

  Raises `Ecto.NoResultsError` if the Lambda does not exist.

  ## Examples

      iex> get_lambda!(user.id, 123)
      %Lambda{}

      iex> get_lambda!(user.id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_lambda!(user_id, id) do
    query = from(l in Lambda, where: [user_id: ^user_id, id: ^id])
    add_detailed_execution_data(Repo.one!(query))
  end

  def get_lambda_by_path!(user_id, path) do
    query = from(l in Lambda, where: [user_id: ^user_id, path: ^path])
    Repo.one(query)
  end

  defp add_detailed_execution_data(lambda) do
    {:ok, id} = Ecto.UUID.dump(lambda.id)
    {:ok, executions} = Repo.query("""
    SELECT  to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800) interval_alias1,
    coalesce(data.c, 0)
    from generate_series(now() - interval '12 hour', now(), '30 minutes'::interval) date
    left outer join (SELECT count(*) c,
                to_timestamp(floor((extract('epoch' from inserted_at) / 1800)) * 1800) as interval_alias
         FROM lambda_executions
         WHERE data->>'status' != 'error'
               AND lambda_id = $1
         GROUP BY interval_alias) as data on data.interval_alias = to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800)
    """, [id])
    {:ok, durations} = Repo.query("""
    SELECT  to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800) interval_alias1,
            coalesce(data.c, 0)
    from generate_series(now() - interval '12 hour', now(), '30 minutes'::interval) date
    left outer join (SELECT sum((data->>'duration')::float) c,
                            to_timestamp(floor((extract('epoch' from inserted_at) / 1800)) * 1800) as interval_alias
                     FROM lambda_executions
                     WHERE data->>'status' != 'error'
                           AND lambda_id = $1
                     GROUP BY interval_alias) as data on data.interval_alias = to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800)
    """, [id])
    {:ok, errors} = Repo.query("""
    SELECT  to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800) interval_alias1,
    coalesce(data.c, 0)
    from generate_series(now() - interval '12 hour', now(), '30 minutes'::interval) date
    left outer join (SELECT count(*) c,
                to_timestamp(floor((extract('epoch' from inserted_at) / 1800)) * 1800) as interval_alias
         FROM lambda_executions
         WHERE data->>'status' = 'error'
               AND lambda_id = $1
         GROUP BY interval_alias) as data on data.interval_alias = to_timestamp(floor((extract('epoch' from date) / 1800)) * 1800)
    """, [id])
    lambda
    |> Map.put(:executions, Enum.map(executions.rows, fn [timestamp, count] -> %{count: count, timestamp: timestamp} end))
    |> Map.put(:durations, Enum.map(durations.rows, fn [timestamp, duration] -> %{duration: duration, timestamp: timestamp} end))
    |> Map.put(:errors, Enum.map(errors.rows, fn [timestamp, count] -> %{count: count, timestamp: timestamp} end))

  end

  def get_lambda_by_path!(path) do
    query = from(l in Lambda, where: l.path == ^path)
    Repo.one(query)
  end

  @doc """
  Creates a lambda.

  ## Examples

      iex> create_lambda(%{field: value})
      {:ok, %Lambda{}}

      iex> create_lambda(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lambda(attrs \\ %{}) do
    %Lambda{}
    |> Lambda.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lambda.

  ## Examples

      iex> update_lambda(lambda, %{field: new_value})
      {:ok, %Lambda{}}

      iex> update_lambda(lambda, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lambda(%Lambda{} = lambda, attrs) do
    lambda
    |> Lambda.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Lambda.

  ## Examples

      iex> delete_lambda(lambda)
      {:ok, %Lambda{}}

      iex> delete_lambda(lambda)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lambda(%Lambda{} = lambda) do
    Repo.delete(lambda)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lambda changes.

  ## Examples

      iex> change_lambda(lambda)
      %Ecto.Changeset{source: %Lambda{}}

  """
  def change_lambda(%Lambda{} = lambda) do
    Lambda.changeset(lambda, %{})
  end

  alias LambdexServer.Lambdas.LambdaExecution

  @doc """
  Returns the list of lambda_executions.

  ## Examples

      iex> list_lambda_executions(user.id, lambda_id)
      [%LambdaExecution{}, ...]

  """
  def list_lambda_executions(user_id, lambda_id) do
    query = from(l in Lambda, where: [user_id: ^user_id, id: ^lambda_id])
    _lambda = Repo.one!(query)
    query = from(le in LambdaExecution, where: [lambda_id: ^lambda_id], order_by: [desc: le.inserted_at])
    Repo.all(query)
  end

  @doc """
  Gets a single lambda_execution.

  Raises `Ecto.NoResultsError` if the Lambda execution does not exist.

  ## Examples

      iex> get_lambda_execution!(123)
      %LambdaExecution{}

      iex> get_lambda_execution!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lambda_execution!(id), do: Repo.get!(LambdaExecution, id)

  @doc """
  Creates a lambda_execution.

  ## Examples

      iex> create_lambda_execution(%{field: value})
      {:ok, %LambdaExecution{}}

      iex> create_lambda_execution(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lambda_execution(attrs \\ %{}) do
    %LambdaExecution{}
    |> LambdaExecution.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lambda_execution.

  ## Examples

      iex> update_lambda_execution(lambda_execution, %{field: new_value})
      {:ok, %LambdaExecution{}}

      iex> update_lambda_execution(lambda_execution, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lambda_execution(%LambdaExecution{} = lambda_execution, attrs) do
    lambda_execution
    |> LambdaExecution.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a LambdaExecution.

  ## Examples

      iex> delete_lambda_execution(lambda_execution)
      {:ok, %LambdaExecution{}}

      iex> delete_lambda_execution(lambda_execution)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lambda_execution(%LambdaExecution{} = lambda_execution) do
    Repo.delete(lambda_execution)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lambda_execution changes.

  ## Examples

      iex> change_lambda_execution(lambda_execution)
      %Ecto.Changeset{source: %LambdaExecution{}}

  """
  def change_lambda_execution(%LambdaExecution{} = lambda_execution) do
    LambdaExecution.changeset(lambda_execution, %{})
  end
end
