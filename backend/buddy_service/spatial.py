from shapely.geometry import Point, LineString
from shapely.ops import transform
import pyproj

# Converts WGS84 (lon/lat) to EPSG:3857 (Web Mercator / Meters)
project_to_meters = pyproj.Transformer.from_crs(
    "EPSG:4326", "EPSG:3857", always_xy=True
).transform

def polyline_to_meters(polyline_coords: list) -> LineString:
    """Converts a raw lon/lat coordinate array into a projected LineString."""
    raw_line = LineString(polyline_coords)
    return transform(project_to_meters, raw_line)

def calculate_cross_track_error(ping_coord: list, route_line_meters: LineString) -> float:
    """Returns the exact perpendicular distance in meters from ping to the route."""
    raw_point = Point(ping_coord[0], ping_coord[1])
    point_in_meters = transform(project_to_meters, raw_point)
    return point_in_meters.distance(route_line_meters)