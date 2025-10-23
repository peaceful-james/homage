defmodule HomageWeb.HomeLive do
  @moduledoc false

  alias Homage.BuildAudioFromTranscript
  alias Phoenix.HTML.Form

  use Gettext, backend: HomageWeb.Gettext
  use HomageWeb, :live_view

  require Logger

  @default_output_mp3_file_name "output"

  @impl LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:building_audio_file, false)
    |> assign(:uploaded_files, [])
    |> allow_upload(:transcript, accept: ~w(.txt), max_entries: 1)
    |> assign_transcript_form(%{"output_file_name" => @default_output_mp3_file_name})
    |> then(&{:ok, &1})
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{}}>
      <.explanation />
      <.transcript_form
        form={@transcript_form}
        uploads={@uploads}
        building_audio_file={@building_audio_file}
      />
    </Layouts.app>
    """
  end

  defp explanation(assigns) do
    ~H"""
    <.header>
      {gettext("Homage - build an audio file from conversation transcripts.")}
      <:subtitle>
        {gettext("Make sure your transcript matches")}
        <div class="relative">
          <.button
            type="button"
            phx-click={
              JS.toggle(to: "#example-transcript-format", in: "fade-in-scale", out: "fade-out-scale")
            }
            phx-disable-with={gettext("Please wait (might take a long time)")}
          >
            {gettext("the expected format.")}
          </.button>
          <.example_transcript_format class="mt-2" />
        </div>
      </:subtitle>
    </.header>
    """
  end

  defp example_transcript_format(assigns) do
    ~H"""
    <div
      id="example-transcript-format"
      class={[
        "hidden",
        "absolute top-full",
        "pb-4 px-4",
        "border bg-base-100 whitespace-pre text-left",
        "z-20"
      ]}
    >
      Speaker 1 0:00
      Hello?

      Speaker 2 0:03
      Greetings, comrade!

      Speaker 1 0:09
      What did you call me? I ain't no commie.

      Speaker 2 0:15
      We are all comrades of mother earth, habibi.

      Speaker 1 0:22
      True, true...
    </div>
    """
  end

  attr :form, Form, required: true
  attr :uploads, :any, required: true
  attr :building_audio_file, :boolean, required: true

  defp transcript_form(assigns) do
    ~H"""
    <div>
      <p class={if !@building_audio_file, do: "hidden"}>
        {gettext("Building audio file... please wait.")}
      </p>
      <.form
        :let={f}
        for={@form}
        id="transcript-form"
        phx-change="change-transcript-form"
        phx-submit="submit-transcript-form"
        class={if @building_audio_file, do: "hidden"}
      >
        <label
          for={@uploads.transcript.ref}
          phx-drop-target={@uploads.transcript.ref}
          class={[
            "my-6 md:my-8",
            "px-6 md:px-8 lg:px-12",
            "mx-2",
            "flex items-center justify-center gap-x-4 md:gap-x-6",
            "p-3 md:p-4 lg:p-5",
            "rounded-xl border border-dashed",
            "text-center",
            if(Enum.any?(@uploads.transcript.entries), do: "hidden")
          ]}
        >
          {gettext("Click here or drag-and-drop your transcript here.")}
          <.live_file_input upload={@uploads.transcript} class="hidden" />
        </label>
        <article :for={entry <- @uploads.transcript.entries} class="upload-entry">
          <figure>
            <.live_img_preview entry={entry} />
            <figcaption>{entry.client_name}</figcaption>
          </figure>

          <progress value={entry.progress} max="100">{entry.progress}% </progress>

          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <p :for={err <- upload_errors(@uploads.transcript, entry)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </article>

        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <p :for={err <- upload_errors(@uploads.transcript)} class="alert alert-danger">
          {error_to_string(err)}
        </p>
        <div
          class={if Enum.empty?(@uploads.transcript.entries), do: "hidden"}
          id="upload-dependant-section"
        >
          <div class="flex items-center gap-x-2 my-4">
            <p>
              {gettext("The output audio file will be named")}
            </p>
            <.input
              field={f[:output_file_name]}
              type="text"
              required
            />
            <p>
              .mp3
            </p>
          </div>
          <.button type="submit" variant="primary">{gettext("Do It")}</.button>
        </div>
      </.form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: gettext("Too large")
  defp error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")
  defp error_to_string(:too_many_files), do: gettext("You have selected too many files")

  defp error_to_string(error) do
    Logger.error("Unexpected user-facing upload error: #{inspect(error)}")
    gettext("Unexpected error occurred: %{error_string}", error_string: inspect(error))
  end

  @impl LiveView
  def handle_event("change-transcript-form", params, socket) do
    socket |> change_transcript_form(params) |> then(&{:noreply, &1})
  end

  def handle_event("submit-transcript-form", params, socket) do
    socket |> submit_transcript_form(params) |> then(&{:noreply, &1})
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :transcript, ref)}
  end

  defp change_transcript_form(socket, params) do
    %{"transcript" => transcript_params} = params
    assign_transcript_form(socket, transcript_params)
  end

  defp submit_transcript_form(socket, params) do
    %{"transcript" => transcript_params} = params

    socket
    |> assign_transcript_form(transcript_params)
    |> start_building_audio_file()
  end

  defp assign_transcript_form(socket, params) do
    transcript_form = to_form(params, as: "transcript")
    assign(socket, :transcript_form, transcript_form)
  end

  defp start_building_audio_file(socket) do
    socket
    |> assign(:building_audio_file, true)
    |> start_async(:build_audio_file, fn -> :ok end)
  end

  @impl LiveView
  def handle_async(:build_audio_file, _, socket) do
    socket |> build_audio_file() |> then(&{:noreply, &1})
  end

  defp build_audio_file(socket) do
    %{transcript_form: transcript_form} = socket.assigns

    mp3_file_name_without_ext =
      transcript_form[:output_file_name].value || @default_output_mp3_file_name

    mp3_file_name = mp3_file_name_without_ext <> ".mp3"

    consume_uploaded_entries(socket, :transcript, fn %{path: path}, _entry ->
      BuildAudioFromTranscript.build_audio_files(path, mp3_file_name)
    end)

    socket
    |> assign(:building_audio_file, false)
    |> put_flash(:info, "Saved to #{mp3_file_name}")
  end
end
