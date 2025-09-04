# Stellarmorphism Phase 2: PostGIS Integration 🌍

## Overview

Phase 2 transforms Stellarmorphism into **GeoFleetic** - a competitive alternative to tile38 and hivekit for fleet-driven geographical information systems. This phase adds PostgreSQL + PostGIS integration, making stellar types persistent and spatially-aware.

## Key Features

### 🗄️ Stellar Persistence
Automatic PostgreSQL schema generation from `defplanet` and `defstar` definitions with full CRUD operations.

### 🌍 Spatial Types
First-class PostGIS integration with spatial orbitals: `moon location :: Geometry.Point`.

### 🚀 Fleet Optimization
Specialized stellar types for vehicles, routes, geofences, and fleet operations.

### ⚡ Real-Time Sync
Automatic database triggers and change streaming for live fleet tracking.

---

## 🗄️ Stellar Persistence

### Enhanced `defplanet` with Ecto Integration

```elixir
defmodule GeoFleetic.Fleet do
  use Stellarmorphism
  
  defplanet Vehicle do
    # Automatic Ecto schema generation
    derive [Ecto.Schema, PostGIS.Geometry]
    
    ecto do
      table "vehicles"
      primary_key {:id, Ecto.UUID, autogenerate: true}
      timestamps()
    end
    
    orbitals do
      moon id :: Ecto.UUID.t(), primary_key: true
      moon callsign :: String.t(), required: true, unique: true
      moon location :: Geometry.Point.t(), srid: 4326  # PostGIS Point with WGS84
      moon heading :: float(), validate: [range: 0..360]
      moon speed :: float(), validate: [min: 0], unit: :kmh
      moon altitude :: float() | nil, unit: :meters
      moon battery_level :: integer(), validate: [range: 0..100]
      moon status :: VehicleStatus.t()
      moon last_seen :: DateTime.t()
      moon route :: asteroid(Route), belongs_to: true
      moon geofences :: [rocket(Geofence)], many_to_many: true
    end
    
    # Auto-generated spatial queries
    spatial_queries do
      query :within_radius, fn lat, lng, radius_km ->
        from v in __MODULE__,
        where: st_dwithin(v.location, st_makepoint(^lng, ^lat, 4326), ^(radius_km * 1000))
      end
      
      query :in_geofence, fn geofence_id ->
        from v in __MODULE__,
        join: g in assoc(v, :geofences),
        where: g.id == ^geofence_id and st_within(v.location, g.boundary)
      end
      
      query :along_route, fn route_id, buffer_meters ->
        from v in __MODULE__,
        join: r in assoc(v, :route),
        where: r.id == ^route_id and st_dwithin(v.location, r.path, ^buffer_meters)
      end
    end
  end
  
  defstar VehicleStatus do
    derive [Ecto.Type, PostGIS.Enum]
    
    layers do
      core Active,
        operational_mode :: atom(), # :driving, :parked, :maintenance
        driver_id :: String.t() | nil
        
      core Inactive,
        reason :: atom(), # :offline, :maintenance, :end_of_shift
        inactive_since :: DateTime.t()
        
      core Emergency,
        alert_type :: atom(), # :panic, :collision, :breakdown
        alert_time :: DateTime.t(),
        responder_notified :: boolean(), default: false
        
      core Maintenance,
        maintenance_type :: atom(), # :scheduled, :breakdown, :inspection
        estimated_completion :: DateTime.t() | nil,
        service_location :: Geometry.Point.t() | nil
    end
    
    # PostGIS Enum storage as JSON with spatial indexing
    ecto_type do
      def type, do: :map
      
      def cast(stellar_value) do
        case stellar_value do
          %{__star__: _} = stellar -> {:ok, stellar}
          map when is_map(map) -> reconstruct_stellar(map)
          _ -> :error
        end
      end
      
      def dump(stellar_value) do
        # Convert to PostGIS-friendly JSON with spatial extraction
        base_map = stellar_to_map(stellar_value)
        
        # Extract spatial data for separate indexing
        spatial_fields = extract_spatial_fields(stellar_value)
        
        {:ok, %{
          stellar_data: base_map,
          spatial_indexes: spatial_fields
        }}
      end
    end
  end
end
```

### Automatic Migration Generation

```bash
# Generate migrations from stellar types
mix stellarmorphism.gen.migration Fleet.Vehicle
```

Generated migration:

```elixir
defmodule GeoFleetic.Repo.Migrations.CreateVehicles do
  use Ecto.Migration
  
  def up do
    # Enable PostGIS extension
    execute "CREATE EXTENSION IF NOT EXISTS postgis"
    
    create table(:vehicles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :callsign, :string, null: false
      add :heading, :float
      add :speed, :float
      add :altitude, :float
      add :battery_level, :integer
      add :status, :map  # JSON storage for stellar sum type
      add :last_seen, :utc_datetime
      add :route_id, references(:routes, type: :uuid)
      timestamps()
    end
    
    # Add PostGIS geometry column with spatial index
    execute "SELECT AddGeometryColumn('vehicles', 'location', 4326, 'POINT', 2)"
    create index(:vehicles, [:location], using: :gist)
    
    # Create indexes for common queries
    create unique_index(:vehicles, [:callsign])
    create index(:vehicles, [:status], using: :gin)  # JSON GIN index
    create index(:vehicles, [:last_seen])
    create index(:vehicles, [:route_id])
    
    # Spatial indexes for common operations
    execute """
    CREATE INDEX vehicles_location_radius_idx 
    ON vehicles USING gist (location) 
    WHERE ST_IsValid(location)
    """
  end
  
  def down do
    drop table(:vehicles)
  end
end
```

---

## 🌍 Spatial Orbital Types

### PostGIS Geometry Integration

```elixir
defmodule GeoFleetic.Spatial do
  use Stellarmorphism
  
  defplanet Route do
    derive [Ecto.Schema, PostGIS.Geometry]
    
    orbitals do
      moon id :: Ecto.UUID.t(), primary_key: true
      moon name :: String.t(), required: true
      moon path :: Geometry.LineString.t(), srid: 4326  # Route polyline
      moon waypoints :: [Geometry.Point.t()], srid: 4326  # Key stops
      moon distance_km :: float()  # Auto-calculated from path
      moon estimated_duration :: integer(), unit: :minutes
      moon difficulty :: atom(), validate: [inclusion: [:easy, :moderate, :hard]]
      moon vehicles :: [asteroid(Vehicle)], has_many: true
      moon active :: boolean(), default: true
    end
    
    # Spatial calculations
    spatial_operations do
      def calculate_distance(route) do
        # Use PostGIS ST_Length with projection
        from r in __MODULE__,
        where: r.id == ^route.id,
        select: fragment("ST_Length(ST_Transform(?, 3857)) / 1000", r.path)
      end
      
      def find_nearest_waypoint(route, location) do
        from r in __MODULE__,
        where: r.id == ^route.id,
        select: fragment("""
          (SELECT waypoint 
           FROM unnest(?) AS waypoint 
           ORDER BY ST_Distance(waypoint, ?) 
           LIMIT 1)
        """, r.waypoints, ^location)
      end
      
      def vehicles_on_route(route, buffer_meters \\ 100) do
        from v in Vehicle,
        where: fragment("ST_DWithin(?, (SELECT path FROM routes WHERE id = ?), ?)", 
                       v.location, ^route.id, ^buffer_meters)
      end
    end
  end
  
  defplanet Geofence do
    derive [Ecto.Schema, PostGIS.Geometry]
    
    orbitals do
      moon id :: Ecto.UUID.t(), primary_key: true
      moon name :: String.t(), required: true
      moon boundary :: Geometry.Polygon.t(), srid: 4326  # Geofence area
      moon fence_type :: GeofenceType.t()
      moon active :: boolean(), default: true
      moon created_by :: String.t()  # User ID
      moon vehicles :: [rocket(Vehicle)], many_to_many: true  # Lazy load for large fleets
    end
    
    # Geofencing operations
    geofence_operations do
      def contains_point?(geofence, point) do
        from g in __MODULE__,
        where: g.id == ^geofence.id,
        select: fragment("ST_Contains(?, ?)", g.boundary, ^point)
      end
      
      def vehicles_inside(geofence) do
        from v in Vehicle,
        join: g in __MODULE__, on: g.id == ^geofence.id,
        where: fragment("ST_Contains(?, ?)", g.boundary, v.location)
      end
      
      def breach_detection(geofence, vehicle_id) do
        # Real-time breach detection with hysteresis
        from v in Vehicle,
        join: g in __MODULE__, on: g.id == ^geofence.id,
        where: v.id == ^vehicle_id,
        select: %{
          is_inside: fragment("ST_Contains(?, ?)", g.boundary, v.location),
          distance_to_edge: fragment("ST_Distance(?, ST_Boundary(?))", v.location, g.boundary),
          fence_type: g.fence_type
        }
      end
    end
  end
  
  defstar GeofenceType do
    derive [Ecto.Type]
    
    layers do
      core InclusionZone,
        description :: String.t(),
        alert_on_exit :: boolean(), default: true
        
      core ExclusionZone, 
        description :: String.t(),
        alert_on_entry :: boolean(), default: true
        
      core SpeedZone,
        speed_limit_kmh :: float(),
        description :: String.t(),
        alert_on_violation :: boolean(), default: true
        
      core ServiceArea,
        service_type :: atom(),  # :fuel, :maintenance, :rest
        operating_hours :: TimeRange.t() | nil
    end
  end
end
```

---

## 🚀 Fleet-Specific Operations

### Real-Time Fleet Management

```elixir
defmodule GeoFleetic.FleetManager do
  use Stellarmorphism
  
  defplanet Fleet do
    derive [Ecto.Schema, PostGIS.Spatial]
    
    orbitals do
      moon id :: Ecto.UUID.t(), primary_key: true
      moon name :: String.t(), required: true
      moon organization_id :: String.t()
      moon home_base :: Geometry.Point.t(), srid: 4326
      moon operating_area :: Geometry.Polygon.t(), srid: 4326  # Service boundary
      moon vehicles :: [asteroid(Vehicle)], has_many: true
      moon routes :: [asteroid(Route)], has_many: true  
      moon geofences :: [asteroid(Geofence)], has_many: true
      moon active :: boolean(), default: true
    end
    
    # Fleet-wide operations
    fleet_operations do
      def vehicle_summary(fleet) do
        from v in Vehicle,
        where: v.fleet_id == ^fleet.id,
        group_by: [fragment("status->>'__star__'")],
        select: %{
          status: fragment("status->>'__star__'"),
          count: count(v.id),
          avg_battery: avg(v.battery_level),
          last_update: max(v.last_seen)
        }
      end
      
      def dispatch_nearest_vehicle(fleet, target_location, constraints \\ []) do
        base_query = from v in Vehicle,
          where: v.fleet_id == ^fleet.id and
                 fragment("status->>'__star__' = 'Active'"),
          order_by: fragment("ST_Distance(?, ?)", v.location, ^target_location),
          limit: 1
        
        # Apply constraints (fuel level, capacity, etc.)
        constrained_query = Enum.reduce(constraints, base_query, fn
          {:min_battery, level}, query ->
            where(query, [v], v.battery_level >= ^level)
          
          {:vehicle_type, type}, query ->
            where(query, [v], fragment("status->'vehicle_type' = ?", ^type))
          
          {:max_distance_km, distance}, query ->
            where(query, [v], fragment("ST_Distance(?, ?) <= ?", 
                                     v.location, ^target_location, ^(distance * 1000)))
        end)
        
        Repo.one(constrained_query)
      end
      
      def route_optimization(fleet, waypoints) do
        # Use PostGIS for traveling salesman problem approximation
        from f in __MODULE__,
        where: f.id == ^fleet.id,
        select: %{
          optimized_route: fragment("""
            WITH points AS (SELECT unnest(?) AS point),
                 distances AS (
                   SELECT a.point AS from_point, b.point AS to_point,
                          ST_Distance(a.point, b.point) AS distance
                   FROM points a CROSS JOIN points b
                   WHERE a.point != b.point
                 )
            SELECT array_agg(from_point ORDER BY distance) 
            FROM distances
          """, ^waypoints),
          total_distance: fragment("""
            SELECT SUM(ST_Distance(
              LAG(point) OVER (ORDER BY ordinality),
              point
            ))
            FROM unnest(?) WITH ORDINALITY AS t(point, ordinality)
          """, ^waypoints)
        }
      end
    end
  end
  
  defstar FleetEvent do
    derive [Ecto.Type, Phoenix.PubSub.Broadcastable]
    
    layers do
      core VehicleLocationUpdate,
        vehicle_id :: String.t(),
        old_location :: Geometry.Point.t(),
        new_location :: Geometry.Point.t(),
        timestamp :: DateTime.t(),
        speed :: float(),
        heading :: float()
        
      core GeofenceBreach,
        vehicle_id :: String.t(),
        geofence_id :: String.t(),
        breach_type :: atom(),  # :entry, :exit
        location :: Geometry.Point.t(),
        timestamp :: DateTime.t()
        
      core RouteDeviation,
        vehicle_id :: String.t(),
        route_id :: String.t(),
        deviation_distance :: float(),
        location :: Geometry.Point.t(),
        timestamp :: DateTime.t()
        
      core MaintenanceAlert,
        vehicle_id :: String.t(),
        alert_type :: atom(),  # :low_battery, :service_due, :malfunction
        severity :: atom(),    # :low, :medium, :high, :critical
        details :: map(),
        timestamp :: DateTime.t()
    end
    
    # Event processing and broadcasting
    event_handling do
      def process_event(event) do
        case event do
          core VehicleLocationUpdate, vehicle_id: id, new_location: location ->
            # Update vehicle location and check geofences
            vehicle = Repo.get(Vehicle, id)
            updated_vehicle = Vehicle.update_location(vehicle, location)
            
            # Check geofence breaches
            breaches = check_geofence_breaches(updated_vehicle)
            Enum.each(breaches, &broadcast_event/1)
            
            # Broadcast location update
            Phoenix.PubSub.broadcast(
              GeoFleetic.PubSub,
              "fleet:#{updated_vehicle.fleet_id}",
              {:location_update, updated_vehicle}
            )
            
          core GeofenceBreach, vehicle_id: v_id, geofence_id: g_id, breach_type: type ->
            # Log breach and trigger alerts
            GeoFleetic.Alerts.create_breach_alert(v_id, g_id, type)
            
            # Broadcast to fleet managers
            Phoenix.PubSub.broadcast(
              GeoFleetic.PubSub, 
              "alerts:geofence:#{g_id}",
              {:geofence_breach, event}
            )
        end
      end
      
      defp check_geofence_breaches(vehicle) do
        # Use PostGIS to efficiently check all relevant geofences
        from g in Geofence,
        where: g.active == true and
               fragment("ST_DWithin(?, ?, 1000)", ^vehicle.location, g.boundary),  # 1km buffer
        select: %{
          geofence: g,
          contains_now: fragment("ST_Contains(?, ?)", g.boundary, ^vehicle.location),
          contained_before: fragment("ST_Contains(?, ?)", g.boundary, ^vehicle.previous_location)
        }
      end
    end
  end
end
```

---

## ⚡ Real-Time Synchronization

### Database Triggers for Live Updates

```sql
-- Auto-generated trigger for vehicle location updates
CREATE OR REPLACE FUNCTION notify_vehicle_location_change()
RETURNS trigger AS $$
BEGIN
  -- Broadcast location changes via LISTEN/NOTIFY
  PERFORM pg_notify(
    'vehicle_location_change',
    json_build_object(
      'vehicle_id', NEW.id,
      'old_location', ST_AsGeoJSON(OLD.location)::json,
      'new_location', ST_AsGeoJSON(NEW.location)::json,
      'timestamp', NEW.updated_at,
      'speed', NEW.speed,
      'heading', NEW.heading
    )::text
  );
  
  -- Check for geofence breaches using PostGIS
  INSERT INTO fleet_events (type, data, created_at)
  SELECT 
    'geofence_breach',
    json_build_object(
      'vehicle_id', NEW.id,
      'geofence_id', g.id,
      'breach_type', 
        CASE 
          WHEN ST_Contains(g.boundary, NEW.location) AND NOT ST_Contains(g.boundary, OLD.location) 
          THEN 'entry'
          WHEN NOT ST_Contains(g.boundary, NEW.location) AND ST_Contains(g.boundary, OLD.location)
          THEN 'exit'
        END,
      'location', ST_AsGeoJSON(NEW.location)::json,
      'timestamp', NEW.updated_at
    ),
    NOW()
  FROM geofences g
  WHERE g.active = true
    AND (
      (ST_Contains(g.boundary, NEW.location) AND NOT ST_Contains(g.boundary, OLD.location)) OR
      (NOT ST_Contains(g.boundary, NEW.location) AND ST_Contains(g.boundary, OLD.location))
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_location_change_trigger
  AFTER UPDATE OF location ON vehicles
  FOR EACH ROW
  EXECUTE FUNCTION notify_vehicle_location_change();
```

### Elixir Event Listener

```elixir
defmodule GeoFleetic.RealtimeListener do
  use GenServer
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  def init(_) do
    {:ok, pid} = Postgrex.Notifications.start_link(GeoFleetic.Repo.config())
    
    # Listen for PostGIS notifications
    Postgrex.Notifications.listen(pid, "vehicle_location_change")
    Postgrex.Notifications.listen(pid, "geofence_breach")
    Postgrex.Notifications.listen(pid, "route_deviation")
    
    {:ok, %{notifications: pid}}
  end
  
  def handle_info({:notification, _connection_pid, _ref, "vehicle_location_change", payload}, state) do
    # Parse PostGIS notification
    event_data = Jason.decode!(payload)
    
    # Create stellar event
    event = core VehicleLocationUpdate,
      vehicle_id: event_data["vehicle_id"],
      old_location: parse_geojson_point(event_data["old_location"]),
      new_location: parse_geojson_point(event_data["new_location"]),
      timestamp: DateTime.from_iso8601!(event_data["timestamp"]),
      speed: event_data["speed"],
      heading: event_data["heading"]
    
    # Process through stellar event system
    GeoFleetic.FleetManager.FleetEvent.process_event(event)
    
    {:noreply, state}
  end
  
  def handle_info({:notification, _connection_pid, _ref, "geofence_breach", payload}, state) do
    event_data = Jason.decode!(payload)
    
    event = core GeofenceBreach,
      vehicle_id: event_data["vehicle_id"],
      geofence_id: event_data["geofence_id"],
      breach_type: String.to_atom(event_data["breach_type"]),
      location: parse_geojson_point(event_data["location"]),
      timestamp: DateTime.from_iso8601!(event_data["timestamp"])
    
    GeoFleetic.FleetManager.FleetEvent.process_event(event)
    
    {:noreply, state}
  end
  
  defp parse_geojson_point(%{"type" => "Point", "coordinates" => [lng, lat]}) do
    %Geometry.Point{coordinates: {lng, lat}, srid: 4326}
  end
end
```

---

## 🎯 Competitive Advantages

### vs. Tile38
- **Persistent Storage**: PostGIS provides durable spatial data vs Tile38's in-memory limitation
- **Type Safety**: Stellar types prevent spatial data corruption
- **Complex Queries**: Full SQL+PostGIS vs Redis-like commands
- **Elixir Concurrency**: Better multi-tenant fleet isolation

### vs. HiveKit  
- **Spatial First**: Native geospatial operations vs general real-time sync
- **Fleet Domain**: Purpose-built for vehicle tracking vs generic collaboration
- **PostGIS Power**: Advanced spatial algorithms vs basic data sync
- **Stellar DSL**: Beautiful fleet modeling vs generic TypeScript

### vs. Both
- **GPU Acceleration**: Phase 4 Nx integration for massive fleet computation
- **Asteroid/Rocket**: Smart lazy/eager loading for optimal performance
- **Elixir OTP**: Fault-tolerant distributed systems
- **Open Source**: No vendor lock-in, full customization

---

## 📊 Performance Characteristics

### Spatial Indexing Strategy
- **GiST Indexes**: For geometry operations (containment, distance)
- **SP-GiST Indexes**: For point-in-polygon optimized queries  
- **BRIN Indexes**: For time-series location data
- **Partial Indexes**: Only active vehicles and geofences

### Query Optimization
- **Spatial Partitioning**: Partition vehicles by geographic region
- **Temporal Partitioning**: Separate current vs historical location data
- **Connection Pooling**: Pgbouncer for high-throughput location updates
- **Read Replicas**: Separate OLTP vs OLAP workloads

Phase 2 establishes GeoFleetic as a formidable competitor with the solid foundation of PostgreSQL + PostGIS, type-safe stellar operations, and real-time streaming capabilities!

---

**Stellarmorphism Phase 2**: Where stellar types meet Earth's geography! 🌍🚀✨