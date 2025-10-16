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
      <div class="relative inline-block text-left">
        <.button
          variant="primary"
          phx-click="toggle_dropdown"
          class="inline-flex justify-center w-full rounded-md shadow-sm px-4 py-2 text-sm font-medium"
          aria-haspopup="true"
          aria-expanded={@dropdown_open}
        >
          Filter Tasks
          <svg
            class={["-mr-1 ml-2 h-5 w-5", if(@dropdown_open, do: "rotate-180", else: "")]}
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </.button>

        <div
          id="dropdownMenu"
          class={"origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-[#fffff2] ring-1 ring-primary ring-opacity-5 focus:outline-none z-50 #{if @dropdown_open, do: "", else: "hidden"}"}
          role="menu"
          aria-orientation="vertical"
          aria-labelledby="menu-button"
          tabindex="-1"
        >
          <div class="py-1" role="none">
            <a
              href="#"
              phx-click="filter"
              phx-value-status="done"
              class="text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer"
              role="menuitem"
              tabindex="-1"
              id="menu-item-0"
            >
              Done
            </a>
            <a
              href="#"
              phx-click="filter"
              phx-value-status="todo"
              class="text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer"
              role="menuitem"
              tabindex="-1"
              id="menu-item-1"
            >
              Todo
            </a>
            <a
              href="#"
              phx-click="filter"
              phx-value-status="expired"
              class="text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer"
              role="menuitem"
              tabindex="-1"
              id="menu-item-2"
            >
              Expired
            </a>
            <a
              href="#"
              phx-click="filter"
              phx-value-status="all"
              class="text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer"
              role="menuitem"
              tabindex="-1"
              id="menu-item-3"
            >
              All
            </a>
          </div>
        </div>
      </div>
      <div class="grid grid-cols-3 gap-5">
        <%= for task <- @tasks do %>
          <div class={"card border-2 rounded-lg shadow p-5 " <>
            (if task.done == true, do: "border-green-500", else: (if NaiveDateTime.compare(task.redline, NaiveDateTime.local_now()) == :lt and task.done == false, do: "border-red-600", else: "border-yellow-600"))}>
            <.link class="text-lg" navigate={~p"/tasks/#{task.id}"}>{task.name}</.link>
            <p class="text-red-400 text-sm">{Calendar.strftime(task.redline, "%H:%M - %d/%m/%Y")}</p>
            <p class="text-lg flex items-center">
              Done?
              <%= if task.done == true do %>
                <.icon name="hero-check-circle" class="text-green-500 text-xs ml-2" />
              <% else %>
                <%= if NaiveDateTime.compare(task.redline, NaiveDateTime.local_now()) == :lt do %>
                  <.icon name="hero-exclamation-circle" class="text-red-600 text-xs ml-2" />
                <% else %>
                  <.link phx-click="mark-done" phx-value-task={task.id}>
                    <.icon name="hero-minus-circle" class="text-yellow-600 text-xs ml-2" />
                  </.link>
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
     |> assign(:dropdown_open, false)
     |> assign(:filter_status, nil)
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

  def handle_event("mark-done", %{"task" => task_id}, socket) do
    _task =
      case Tasks.get_task!(socket.assigns.current_scope, task_id) do
        nil ->
          {:noreply, put_flash(socket, :error, "Error, Task not found")}

        task ->
          if NaiveDateTime.compare(task.redline, NaiveDateTime.local_now()) == :lt do
            {:noreply, put_flash(socket, :error, "The task has expired!")}
          else
            case Tasks.update_task(socket.assigns.current_scope, task, %{done: true}) do
              {:ok, updated_task} ->
                tasks = Tasks.list_tasks(socket.assigns.current_scope)

                {:noreply,
                 socket
                 |> assign(:tasks, tasks)
                 |> put_flash(:success, "Task #{updated_task.name} completed!")}

              {:error, _changeset} ->
                {socket, :error, "Could not mark this task as done."}
            end
          end
      end
  end

  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: !socket.assigns.dropdown_open)}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    tasks =
      case status do
        "done" -> Tasks.load_tasks_done(socket.assigns.current_scope)
        "todo" -> Tasks.load_tasks_todo(socket.assigns.current_scope)
        "expired" -> Tasks.load_tasks_expired(socket.assigns.current_scope)
        "all" -> Tasks.list_tasks(socket.assigns.current_scope)
        _ -> Tasks.list_tasks(socket.assigns.current_scope)
      end

    {:noreply,
     socket
     |> assign(filter_status: status, tasks: tasks, dropdown_open: false)}
  end

  defp list_tasks(current_scope) do
    Tasks.list_tasks(current_scope)
  end
end
