defmodule Mix.Tasks.DiffPb do
  use Mix.Task
  alias GTFSRealtimeViz.State

  def run([first, second]) do
    Application.ensure_all_started(:gtfs_realtime_viz)
    GTFSRealtimeViz.new_message(:first, File.read!(first), first)
    GTFSRealtimeViz.new_message(:second, File.read!(second), second)
    first_vehicles = vehicles(:first)
    second_vehicles = vehicles(:second)
    IO.inspect(diff_pairs(first_vehicles, second_vehicles, &vehicle_sort_key/1, &vehicle_diff/3))
  end

  def vehicles(group) do
    [{_, vehicles}] = State.vehicles(group)
    Enum.sort_by(vehicles, &vehicle_sort_key/1)
  end

  def vehicle_sort_key(%{vehicle: %{id: id}}), do: id
  def vehicle_sort_key(_), do: nil

  def diff_pairs(first, [], _, _) do
    for item <- first do
      {:removed, first}
    end
  end

  def diff_pairs([], second, _, _) do
    for item <- second do
      {:added, second}
    end
  end

  def diff_pairs([first | rest_first], [second | rest_second], key_fn, diff_fn) do
    first_key = key_fn.(first)
    second_key = key_fn.(second)
    cond do
      first_key == second_key ->
        diff_fn.(first_key, first, second) ++ diff_pairs(rest_first, rest_second, key_fn, diff_fn)
      first_key <= second_key ->
        [{:removed, first}] ++ diff_pairs(rest_second, [second | rest_second], key_fn, diff_fn)
      true ->
        [{:added, second}] ++ diff_pairs([first | rest_first], rest_second, key_fn, diff_fn)
    end
  end

  def vehicle_diff(key, first, second) do
    for key <- [[:current_status], [:current_stop_sequence], [:trip, :trip_id]],
      first_val = Access.get(first, key),
      second_val = Access.get(second, key),
      first_val != second_val do
        {:changed, key, first_val, second_val}
    end
  end
end
