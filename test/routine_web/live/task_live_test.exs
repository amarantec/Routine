defmodule RoutineWeb.TaskLiveTest do
  use RoutineWeb.ConnCase

  import Phoenix.LiveViewTest
  import Routine.TasksFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    redline: ~N[2025-10-13T18:24:00.000000]
  }
  @update_attrs %{
    name: "some updated name",
    done: false,
    description: "some updated description",
    redline: ~N[2025-10-14T18:24:00.000000]
  }
  @invalid_attrs %{name: nil, description: nil, redline: nil}

  setup :register_and_log_in_user

  defp create_task(%{scope: scope}) do
    task = task_fixture(scope)

    %{task: task}
  end

  describe "Index" do
    setup [:create_task]

    test "lists all tasks", %{conn: conn, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks")

      assert html =~ "Listing Tasks"
      assert html =~ task.name
    end

    test "saves new task", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Task")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/new")

      assert render(form_live) =~ "New Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#task-form", task: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Task created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_task]

    test "displays task", %{conn: conn, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.name
    end

    test "updates task and returns to show", %{conn: conn, task: task, scope: scope} do
      future_redline = NaiveDateTime.add(NaiveDateTime.local_now(), 3600, :second)

      task_attrs =
        @create_attrs
        |> Map.put(:redline, future_redline)
        |> Map.put(:done, false)

      task = task_fixture(scope, task_attrs)

      {:ok, show_live, _html} = live(conn, ~p"/tasks/#{task}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/#{task}/edit?return_to=show")

      assert render(form_live) =~ "Edit Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#task-form", task: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks/#{task}")

      html = render(show_live)
      assert html =~ "Task updated successfully"
      assert html =~ "some updated name"
    end
  end
end
