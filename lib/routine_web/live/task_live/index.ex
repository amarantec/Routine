defmodule RoutineWeb.TaskLive.Index do
  use RoutineWeb, :live_view

  alias Routine.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Tasks
        <:actions>
          <.button variant="primary" navigate={~p"/tasks/new"}>
            <.icon name="hero-plus" /> New Task
          </.button>
        </:actions>
      </.header>

      <div class="grid grid-cols-3 gap-5">
        <%= for task <- @tasks do %>
          <div class={"card border-2 rounded-lg shadow p-5 " <>
            (if task.done == :true, do: "border-green-500", else: if NaiveDateTime.local_now() > task.redline, do: "border-red-600", else: "border-white")}>
            <.link class="text-white text-lg" navigate={~p"/tasks/#{task.id}"}>{task.name}</.link>
            <p class="text-red-400 text-sm">{Calendar.strftime(task.redline, "%H:%M - %d/%m/%Y")}</p>
            <p class="text-white text-lg">
              Done?
              <%= if task.done == :true do %>
                <.icon name="hero-check-circle" class="text-green-500 text-sm" />
              <% else %>
                <%= if NaiveDateTime.local_now() > task.redline do %>
                  <.icon name="hero-exclamation-circle" class="text-red-600 text-sm" />
                <% else %>
                  <.icon name="hero-minus-circle" class="text-white text-sm" />
                <% end %>
              <% end %>
            </p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe_tasks(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Tasks")
     |> assign(:tasks, list_tasks(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(socket.assigns.current_scope, id)
    {:ok, _} = Tasks.delete_task(socket.assigns.current_scope, task)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def handle_info({type, %Routine.Tasks.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :tasks, list_tasks(socket.assigns.current_scope), reset: true)}
  end

  defp list_tasks(current_scope) do
    Tasks.list_tasks(current_scope)
  end
end
