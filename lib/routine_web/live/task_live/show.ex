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
          <%= if @task.done == true do %>
            <.button>
              <.icon name="hero-bookmark-square" class="text-xs" />
            </.button>
          <% else %>
            <%= if NaiveDateTime.compare(@task.redline, NaiveDateTime.local_now()) == :lt do %>
              <.button>
                <.icon
                  name="hero-exclamation-triangle"
                  class="text-xs"
                />
              </.button>
            <% else %>
              <.button phx-click="mark_done" phx-value-task={@task.id}>
                <.icon
                  name="hero-bookmark"
                  class="text-xs"
                />
              </.button>
            <% end %>
          <% end %>
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
        <:item title="Review">{@task.review}</:item>
      </.list>

      <%= if NaiveDateTime.compare(@task.redline, NaiveDateTime.local_now()) == :lt or @task.done == true do %>
        <%= if @task.review != "" and @task.review != nil do %>
          <div class="p-4 bg-green-100 border border-green-400 text-green-700 rounded">
            Review already submitted!
          </div>
        <% else %>
          <.form
            for={@form}
            id="task-review-form"
            phx-change="validate_review"
            phx-submit="save_review"
          >
            <.input field={@form[:review]} type="textarea" label="Review" />
            <div class="mt-4">
              <.button type="submit" variant="primary">Save review</.button>
            </div>
          </.form>
        <% end %>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe_tasks(socket.assigns.current_scope)
    end

    task = Tasks.get_task!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, "Show Task")
     |> assign(:task, task)
     |> apply_action(socket.assigns.live_action)}
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

  defp apply_action(socket, :show) do
    socket
    |> assign(:page_title, "Show Task")
    |> assign(
      :form,
      to_form(Tasks.change_task(socket.assigns.current_scope, socket.assigns.task))
    )
  end

  defp apply_action(socket, :edit, task) do
    socket
    |> assign(:page_title, "Submit a Review")
    |> assign(:task, task)
    |> assign(:form, to_form(Tasks.change_task(socket.assigns.current_scope, task)))
  end

  def handle_event("mark_done", %{"task" => task_id}, socket) do
    task = Tasks.get_task!(socket.assigns.current_scope, task_id)

    cond do
      NaiveDateTime.compare(task.redline, NaiveDateTime.local_now()) == :lt ->
        {:noreply, put_flash(socket, :error, "Task has expired")}

      true ->
        case Tasks.update_task(socket.assigns.current_scope, task, %{done: true}) do
          {:ok, _task} ->
            {:noreply, put_flash(socket, :success, "Task completed")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not mark this task as done")}
        end
    end
  end

  def handle_event("validate_review", %{"task" => review_params}, socket) do
    changeset = review_changeset(socket.assigns.task, review_params)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_review", %{"task" => review_params}, socket) do
    case Tasks.update_task(socket.assigns.current_scope, socket.assigns.task, review_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Review submitted successfully")
         |> assign(:task, task)
         |> assign(:form, to_form(Tasks.change_task(socket.assigns.current_scope, task)))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp review_changeset(task, attrs) do
    task
    |> Ecto.Changeset.cast(attrs, [:review])
    |> Ecto.Changeset.validate_required([:review])
  end

  defp return_path(_scope, "index", _task), do: ~p"/tasks"
  defp return_path(_scope, "show", task), do: ~p"/tasks/#{task}"
end
