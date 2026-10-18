# LumaWalk

LumaWalk is a safety-aware walking navigation demo. It requests Safe and Direct
walking routes from the FastAPI backend using the user's current or simulated
location.

## Using the map

1. Allow location access or enable simulation mode.
2. Type a place or address in the destination search box and choose a result.
3. Select the Safe or Direct route, then start navigation.
4. Follow the map and spoken turn instructions. The selected route remains
   fixed during navigation.
5. At the destination, confirm arrival or choose another map point.

Destination search uses OpenStreetMap Nominatim. Safe-haven markers are loaded
from `assets/mock_data/real_havens_petaling_jaya.geojson`. Route data comes from
the FastAPI backend. The map uses OpenStreetMap tiles and displays contributor
attribution.
