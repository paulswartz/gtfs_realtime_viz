defmodule Mix.Tasks.DiffPb do
  use Mix.Task
  alias GTFSRealtimeViz.State

  def run([first, second]) do
    Application.ensure_all_started(:gtfs_realtime_viz)
    GTFSRealtimeViz.new_message(:first, File.read!(first), first)
    GTFSRealtimeViz.new_message(:second, File.read!(second), second)
    first_vehicles = vehicles(:first)
    second_vehicles = vehicles(:second)
    first_trip_updates = trip_updates(:first)
    second_trip_updates = trip_updates(:second)
    for diff <- diff_pairs(first_vehicles, second_vehicles, &vehicle_sort_key/1, &vehicle_diff/3) do
      IO.inspect(diff)
    end
    for diff <- diff_pairs(first_trip_updates, second_trip_updates, &trip_update_sort_key/1, &trip_update_diff/3),
      elem(diff, 0) == :changed do
      IO.inspect(diff)
    end
  end

  def vehicles(group) do
    [{_, vehicles}] = State.vehicles(group)
    Enum.sort_by(vehicles, &vehicle_sort_key/1)
  end

  def trip_updates(group) do
    [{_, trip_updates}] = State.trip_updates(group)
    Enum.sort_by(trip_updates, &trip_update_sort_key/1)
  end

  def vehicle_sort_key(%{vehicle: %{id: id}, trip: trip}), do: {id, trip.route_id, trip.direction_id}
  def vehicle_sort_key(_), do: nil

  def trip_update_sort_key(%{trip: %{} = trip}), do: {trip.trip_id, trip.route_id, trip.direction_id}
  def trip_update_sort_key(_), do: nil

  def diff_pairs(first, [], key_fn, _) do
    for item <- first do
      {:removed, key_fn.(item)}
    end
    []
  end

  def diff_pairs([], second, key_fn, _) do
    for item <- second do
      {:added, key_fn.(item)}
    end
    []
  end

  def diff_pairs([first | rest_first], [second | rest_second], key_fn, diff_fn) do
    first_key = key_fn.(first)
    second_key = key_fn.(second)
    cond do
      first_key == second_key ->
        diff_fn.(first_key, first, second) ++ diff_pairs(rest_first, rest_second, key_fn, diff_fn)
      is_nil(first_key) ->
        [{:no_first_key, first}] ++ diff_pairs(rest_first, [second | rest_second], key_fn, diff_fn)
      is_nil(second_key) ->
        [{:no_second_key, second}] ++ diff_pairs([first | rest_first], rest_second, key_fn, diff_fn)
      first_key < second_key ->
        #[{:removed, first_key}] ++
        diff_pairs(rest_first, [second | rest_second], key_fn, diff_fn)
      first_key > second_key ->
        #[{:added, second_key}] ++
          diff_pairs([first | rest_first], rest_second, key_fn, diff_fn)
    end
  end

  def vehicle_diff(key, first, second) do
    diff_functions(key, first, second, [trip_id: & &1.trip.trip_id, stop_sequence: & &1.current_stop_sequence])
  end

  def trip_update_diff(key, _first, %{stop_time_update: []}) do
    [{:changed, key, :removed_stop_updates}]
  end
  def trip_update_diff(key, %{stop_time_update: []}, _second) do
    [{:changed, key, :added_stop_updates}]
  end
  def trip_update_diff(key, first, second) do
    tu_diffs = diff_functions(key, first, second, [relationship: & &1.trip.schedule_relationship])
    first = Enum.uniq(Enum.sort_by(first.stop_time_update, & &1.stop_sequence))
    second = Enum.sort_by(second.stop_time_update, & &1.stop_sequence)
    stu_diffs = for diff <- diff_pairs(first, second, & &1.stop_sequence, &stop_sequence_diff/3) do
      {:changed, key, diff}
    end
    tu_diffs ++ stu_diffs
  end

  def stop_sequence_diff(key, first, second) do
    diff_functions(key, first, second, [relationship: & &1.schedule_relationship, has_arrival?: &not is_nil(&1.arrival), has_departure?: &not is_nil(&1.departure)])
  end

  def diff_functions(key, first, second, functions) do
    for {name, val_fn} <- functions,
      first_val = val_fn.(first),
      second_val = val_fn.(second),
      not valid?(name, first_val, second_val) do
        {:changed, key, name, first_val, second_val}
    end
  end

  defp valid?(:relationship, first_val, second_val) do
    first_val = first_val || :SCHEDULED
    second_val = second_val || :SCHEDULED
    first_val == second_val
  end
  defp valid?(:stop_sequence, first_val, second_val) when is_integer(second_val) and first_val <= second_val do
    true
  end
  defp valid?(_, same, same) do
    true
  end
  defp valid?(_, _, _) do
    false
  end
end
