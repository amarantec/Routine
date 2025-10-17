defmodule Routine.TasksTest do
  use Routine.DataCase

  alias Routine.Tasks

  describe "tasks" do
    alias Routine.Tasks.Task

    import Routine.AccountsFixtures, only: [user_scope_fixture: 0]
    import Routine.TasksFixtures

    @invalid_attrs %{name: nil, done: nil, description: nil, redline: nil}

    test "list_tasks/1 returns all scoped tasks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(other_scope)
      assert Tasks.list_tasks(scope) == [task]
      assert Tasks.list_tasks(other_scope) == [other_task]
    end

    test "get_task!/2 returns the task with given id" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_scope = user_scope_fixture()
      assert Tasks.get_task!(scope, task.id) == task
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(other_scope, task.id) end
    end

    test "create_task/2 with valid data creates a task" do
      valid_attrs = %{
        name: "some name",
        done: true,
        description: "some description",
        redline: ~N[2025-10-13 18:24:00.000000]
      }

      scope = user_scope_fixture()

      assert {:ok, %Task{} = task} = Tasks.create_task(scope, valid_attrs)
      assert task.name == "some name"
      assert task.done == true
      assert task.description == "some description"
      assert task.redline == ~N[2025-10-13 18:24:00.000000]
      assert task.user_id == scope.user.id
    end

    test "create_task/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(scope, @invalid_attrs)
    end

    test "update_task/3 with valid data updates the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        done: false,
        description: "some updated description",
        redline: ~N[2025-10-14 18:24:00.000000]
      }

      assert {:ok, %Task{} = task} = Tasks.update_task(scope, task, update_attrs)
      assert task.name == "some updated name"
      assert task.done == false
      assert task.description == "some updated description"
      assert task.redline == ~N[2025-10-14 18:24:00.000000]
    end

    test "update_task/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise MatchError, fn ->
        Tasks.update_task(other_scope, task, %{})
      end
    end

    test "update_task/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(scope, task, @invalid_attrs)
      assert task == Tasks.get_task!(scope, task.id)
    end

    test "delete_task/2 deletes the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert {:ok, %Task{}} = Tasks.delete_task(scope, task)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, task.id) end
    end

    test "delete_task/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      assert_raise MatchError, fn -> Tasks.delete_task(other_scope, task) end
    end

    test "change_task/2 returns a task changeset" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert %Ecto.Changeset{} = Tasks.change_task(scope, task)
    end

    test "load_tasks_done/1 return all scoped tasks where done is true" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(other_scope)
      assert Tasks.load_tasks_done(scope) == [task]
      assert Tasks.load_tasks_done(other_scope) == [other_task]
    end

    test "load_tasks_todo/1 return all scoped tasks where done is false" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope, %{done: false, redline: NaiveDateTime.add(NaiveDateTime.local_now(), 86,400)})
      other_task = task_fixture(other_scope, %{done: false, redline: NaiveDateTime.add(NaiveDateTime.local_now(), 86,400)})
      assert Tasks.load_tasks_todo(scope) == [task]
      assert Tasks.load_tasks_todo(other_scope) == [other_task]
    end

    test "load_tasks_expired/1 return all scoped tasks where done is false and redline has expired" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope, %{done: false, redline: NaiveDateTime.add(NaiveDateTime.local_now(), -86,400)})
      other_task = task_fixture(other_scope, %{done: false, redline: NaiveDateTime.add(NaiveDateTime.local_now(), -86,400)})
      assert Tasks.load_tasks_expired(scope) == [task]
      assert Tasks.load_tasks_expired(other_scope) == [other_task]
    end
  end
end
