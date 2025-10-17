defmodule RoutineWeb.TaskLive.Show do
  use RoutineWeb, :live_view

  alias Routine.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Task {@task.name}
        <:subtitle>This is a task record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/tasks"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/tasks/#{@task}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit task
          </.button>
          <.button
            phx-click={JS.push("delete", value: %{id: @task.id}) |> hide("##{@task.id}")}
            data-confirm="Are you sure?"
          >
            <.icon name="hero-trash" />
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Description">{@task.description}</:item>
        <:item title="Done">{@task.done}</:item>
        <:item title="Redline">{Calendar.strftime(@task.redline, "%H:%M - %d/%m/%Y")}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe_tasks(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Task")
     |> assign(:task, Tasks.get_task!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Routine.Tasks.Task{id: id} = task},
        %{assigns: %{task: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :task, task)}
  end

  def handle_info(
        {:deleted, %Routine.Tasks.Task{id: id}},
        %{assigns: %{task: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current task was deleted.")
     |> push_navigate(to: ~p"/tasks")}
  end

  def handle_info({type, %Routine.Tasks.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => task_id}, socket) do
    task = Tasks.get_task!(socket.assigns.current_scope, task_id)

    {:ok, _} =
      Tasks.delete_task(socket.assigns.current_scope, task)

    {:noreply, assign(socket, deleted_task: task)}
  end
end
