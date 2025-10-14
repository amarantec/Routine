defmodule Routine.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Routine.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        done: true,
        name: "some name",
        redline: ~N[2025-10-13 18:24:00.000000]
      })

    {:ok, task} = Routine.Tasks.create_task(scope, attrs)
    task
  end
end
