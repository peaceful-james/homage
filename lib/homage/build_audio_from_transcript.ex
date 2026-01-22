defmodule Homage.BuildAudioFromTranscript do
  @moduledoc """
  The module name says it all - build audio from transcript files
  """

  alias Homage.GTTS
  require Logger

  @typedoc """
  Line indicating speaker change

  e.g. "Speaker 1 12:34"
  """
  @type speaker_line :: String.t()

  @type file_name :: String.t()

  @type acc :: %{
          :speaker_number => integer() | nil,
          :reversed_to_speak => [String.t()],
          :file_idx => integer(),
          :reversed_file_names => [file_name()]
        }

  @doc """
  Read a file and for each non-empty line, switches speaker or reads it
  """
  @spec build_audio_files(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def build_audio_files(file_path, output_file_name \\ "./output.mp3") do
    output_file_path = Path.expand(output_file_name)

    audio_dir =
      Path.join(System.tmp_dir!(), "homage-audio-#{System.unique_integer([:positive])}")

    log("Creating audio directory: #{audio_dir}")
    :ok = File.mkdir_p!(audio_dir)

    final_acc =
      file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.filter(&(&1 != ""))
      |> Enum.reduce(
        %{speaker_number: nil, reversed_to_speak: [], file_idx: 0, reversed_file_names: []},
        fn line, acc ->
          log(line)

          if is_speaker_line?(line) do
            %{speaker_number: speaker_number, reversed_file_names: reversed_file_names} = acc

            new_reversed_file_names =
              if speaker_number do
                build_temp_file_for_same_speaker_lines(acc, audio_dir)
              else
                reversed_file_names
              end

            new_speaker_number = infer_speaker_number(line)

            %{
              speaker_number: new_speaker_number,
              reversed_to_speak: [],
              file_idx: acc.file_idx + 1,
              reversed_file_names: new_reversed_file_names
            }
          else
            Map.update!(acc, :reversed_to_speak, &[line | &1])
          end
        end
      )

    reversed_file_names = build_temp_file_for_same_speaker_lines(final_acc, audio_dir)

    {existing_file_names, missing_files} =
      Enum.split_with(reversed_file_names, &File.exists?/1)

    if missing_files != [] do
      Logger.error("Missing generated audio files: #{Enum.join(missing_files, ", ")}")
    end

    result =
      case existing_file_names do
        [] ->
          {:error, "No audio files were successfully generated"}

        _ ->
          concat_audio_files(existing_file_names, output_file_path)
      end

    File.rm_rf!(audio_dir)

    case result do
      {:ok, ^output_file_path} ->
        log("Generated audio file: #{output_file_path}")
        {:ok, output_file_path}

      {:error, reason} ->
        Logger.error("Failed to build audio: #{reason}")
        {:error, reason}
    end
  end

  @spec build_temp_file_for_same_speaker_lines(acc(), String.t()) :: [file_name()]
  defp build_temp_file_for_same_speaker_lines(acc, audio_dir) do
    %{
      speaker_number: speaker_number,
      reversed_to_speak: reversed_to_speak,
      file_idx: file_idx,
      reversed_file_names: reversed_file_names
    } = acc

    text_to_speak = Enum.reverse(reversed_to_speak) |> Enum.join(" ")

    # Skip if text is empty
    if text_to_speak == "" do
      reversed_file_names
    else
      file_name = "#{audio_dir}/#{file_idx}_spkr_#{speaker_number}.mp3"

      case GTTS.speak_text_to_file(text_to_speak, speaker_number, file_name) do
        {:ok, _} ->
          [file_name | reversed_file_names]

        {:error, reason} ->
          Logger.error("Failed to generate audio for speaker #{speaker_number}: #{reason}")
          reversed_file_names
      end
    end
  end

  @spec is_speaker_line?(String.t()) :: boolean()
  defp is_speaker_line?(line) do
    String.match?(line, ~r/^Speaker \d* \d*:\d*/)
  end

  @spec infer_speaker_number(speaker_line()) :: integer()
  defp infer_speaker_number(line) do
    [^line, _, speaker_num, _time] = Regex.run(~r/^(Speaker) (\d*) (\d*:\d*)/, line)
    String.to_integer(speaker_num)
  end

  defp concat_audio_files(reversed_file_names, output_file_name) do
    file_names = Enum.reverse(reversed_file_names)
    count = length(file_names)

    inputs = Enum.flat_map(file_names, fn file -> ["-i", file] end)
    streams = Enum.map_join(0..(count - 1), "", fn i -> "[#{i}:0]" end)
    filter = "#{streams}concat=n=#{count}:v=0:a=1[out]"

    args = ["-y"] ++ inputs ++ ["-filter_complex", filter, "-map", "[out]", output_file_name]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} ->
        {:ok, output_file_name}

      {error_message, _exit_code} ->
        {:error, "Failed to generate audio: #{String.trim(error_message)}"}
    end
  end

  defp log(text) do
    Logger.debug(text)
  end
end
