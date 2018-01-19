#!/bin/sh
set -e
#wget -O /tmp/vp.pb "http://developer.mbta.com/lib/GTRTFS/Alerts/VehiclePositions.pb"
#wget -O /tmp/tu.pb "http://developer.mbta.com/lib/GTRTFS/Alerts/TripUpdates.pb"
#wget -O /tmp/tu.pb "https://s3.amazonaws.com/mbta-realtime-prod/tripupdates.pb"
wget -O /tmp/vp.pb "https://s3.amazonaws.com/mbta-realtime-prod/vehiclepositions.pb"

wget -O /tmp/VehiclePositions.pb "https://s3.amazonaws.com/mbta-gtfs-s3/concentrate/VehiclePositions.pb"

mix diff_pb /tmp/vp.pb /tmp/VehiclePositions.pb
