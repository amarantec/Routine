defmodule Routine.Repo.Migrations.AddTaskReview do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add(:review, :text)
    end
  end
end
