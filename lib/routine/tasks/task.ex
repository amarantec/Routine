defmodule Routine.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field :name, :string
    field :description, :string
    field :done, :boolean, default: false
    field :redline, :naive_datetime_usec
    field :review, :string
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs, user_scope) do
    task
    |> cast(attrs, [:name, :description, :done, :redline])
    |> validate_required([:name, :description, :done, :redline])
    |> put_change(:user_id, user_scope.user.id)
  end
end
