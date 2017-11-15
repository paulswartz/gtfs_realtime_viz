defmodule GTFSRealtimeVizTest do
  use ExUnit.Case

  alias GTFSRealtimeViz.Proto

  test "visualizes a file" do
    data = %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: [
        %Proto.FeedEntity{
          id: "123",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "this_is_the_route_id",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "this_is_the_vehicle_id",
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{"route" => [["stop", "this_is_the_stop_id", "outbound"]]})

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
  end

  test "displays info about the stops given in for the route" do
    data = %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: [
        %Proto.FeedEntity{
          id: "123",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "this_is_the_route_id",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "this_is_the_vehicle_id",
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{"Route" => [["First Stop", "this_is_the_stop_id", "124"], ["Middle Stop", "125", "126"], ["End Stop", "127", "128"]]})

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
    assert viz =~ "First Stop"
    assert viz =~ "Middle Stop"
    assert viz =~ "End Stop"
  end

  test "displays info about each route in the options" do
    data = %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: [
        %Proto.FeedEntity{
          id: "123",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "this_is_the_route_id",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "this_is_the_vehicle_id",
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{"First Route" => [["FR Only Stop", "this_is_the_stop_id", "124"]], "Second Route" => [["SR Only Stop", "125", "126"]]})

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
    assert viz =~ "First Route"
    assert viz =~ "FR Only Stop"
    assert viz =~ "Second Route"
    assert viz =~ "SR Only Stop"
  end

  test "Only displays the given routes, even if there is data about other routes" do
    data = %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: [
        %Proto.FeedEntity{
          id: "123",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "this_is_the_route_id",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "this_is_the_vehicle_id",
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        },
        %Proto.FeedEntity{
          id: "124",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "secondary_trip_id",
              route_id: "other_route",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "different_vehicle",
              label: "different_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 1.00,
              longitude: 1.00,
            },
            stop_id: "126",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{"First Route" => [["FR Only Stop", "this_is_the_stop_id", "124"]]})

    refute viz =~ "other_route"
    refute viz =~ "different_vehicle"
    assert viz =~ "this_is_the_vehicle_id"
  end

  describe "locations_we_care_about/1" do
    test "turns a map of route name -> list of lists describing the stops into a list of all stops on all routes" do
      routes = %{"First Route" => [["FR Only Stop", "123", "124"]], "Second Route" => [["SR First Stop", "125", "126"], ["SR Second Stop", "234", "432"]]}
      assert GTFSRealtimeViz.locations_we_care_about(routes) == ["FR Only Stop", "123", "124", "SR First Stop", "125", "126", "SR Second Stop", "234", "432"]
    end
  end

  describe "vehicles_we_care_about/2" do
    test "removes vehicle positions at stop ids we dont care about" do
      locations_we_care_about = ["FR Only Stop", "123", "124", "SR First Stop", "125", "126", "SR Second Stop", "234", "432"]
      state = [{"this is the test data",
                [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
                   current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
                   occupancy_status: nil,
                   position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 0.0,
                     longitude: 0.0, odometer: nil, speed: nil}, stop_id: "123",
                    timestamp: nil,
                    trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                      route_id: "this_is_the_route_id", schedule_relationship: nil,
                      start_date: nil, start_time: nil, trip_id: "this_is_the_trip_id"},
                    vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "this_is_the_vehicle_id",
                      label: "this_is_the_vehicle_label", license_plate: nil}}]},
              {"this is the test data",
                [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
                   current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
                   occupancy_status: nil,
                   position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 0.0,
                     longitude: 0.0, odometer: nil, speed: nil}, stop_id: "124",
                    timestamp: nil,
                    trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                      route_id: "this_is_the_route_id", schedule_relationship: nil,
                      start_date: nil, start_time: nil, trip_id: "this_is_the_trip_id"},
                    vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "this_is_the_vehicle_id",
                      label: "this_is_the_vehicle_label", license_plate: nil}}]},
              {"this is the test data",
                [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
                   current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
                   occupancy_status: nil,
                   position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 0.0,
                     longitude: 0.0, odometer: nil, speed: nil}, stop_id: "321",
                    timestamp: nil,
                    trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                      route_id: "this_is_the_route_id", schedule_relationship: nil,
                      start_date: nil, start_time: nil, trip_id: "this_is_the_trip_id"},
                    vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "this_is_the_vehicle_id",
                      label: "this_is_the_vehicle_label", license_plate: nil}},
                  %GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
                    current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
                    occupancy_status: nil,
                    position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 1.0,
                      longitude: 1.0, odometer: nil, speed: nil}, stop_id: "432", timestamp: nil,
                    trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                      route_id: "other_route", schedule_relationship: nil, start_date: nil,
                      start_time: nil, trip_id: "secondary_trip_id"},
                    vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "different_vehicle",
                      label: "different_vehicle_label", license_plate: nil}}]}]
      assert GTFSRealtimeViz.vehicles_we_care_about(state, locations_we_care_about) ==
        [{"this is the test data",
           [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
              current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
              occupancy_status: nil,
              position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 0.0,
                longitude: 0.0, odometer: nil, speed: nil}, stop_id: "123",
              timestamp: nil,
              trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                route_id: "this_is_the_route_id", schedule_relationship: nil,
                start_date: nil, start_time: nil, trip_id: "this_is_the_trip_id"},
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "this_is_the_vehicle_id",
                label: "this_is_the_vehicle_label", license_plate: nil}}]},
        {"this is the test data",
          [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
             current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
             occupancy_status: nil,
             position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 0.0,
               longitude: 0.0, odometer: nil, speed: nil}, stop_id: "124",
              timestamp: nil,
              trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                route_id: "this_is_the_route_id", schedule_relationship: nil,
                start_date: nil, start_time: nil, trip_id: "this_is_the_trip_id"},
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "this_is_the_vehicle_id",
                label: "this_is_the_vehicle_label", license_plate: nil}}]},
        {"this is the test data",
          [%GTFSRealtimeViz.Proto.VehiclePosition{congestion_level: nil,
              current_status: :IN_TRANSIT_TO, current_stop_sequence: nil,
              occupancy_status: nil,
              position: %GTFSRealtimeViz.Proto.Position{bearing: nil, latitude: 1.0,
                longitude: 1.0, odometer: nil, speed: nil}, stop_id: "432", timestamp: nil,
              trip: %GTFSRealtimeViz.Proto.TripDescriptor{direction_id: 0,
                route_id: "other_route", schedule_relationship: nil, start_date: nil,
                start_time: nil, trip_id: "secondary_trip_id"},
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{id: "different_vehicle",
                label: "different_vehicle_label", license_plate: nil}}]}]
    end
  end
end
