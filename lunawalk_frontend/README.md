# LumaWalk

LumaWalk is a safety-aware walking navigation demo. It requests Safe and Direct
walking routes from the FastAPI backend using the user's current or simulated
location.

## Running the frontend

From the `lunawalk_frontend` directory, install the Flutter dependencies and
launch the app in a supported device or browser:

```powershell
cd "c:\Documents\docs\Desktop\LumaWalk\LumaWalk\lunawalk_frontend"
flutter pub get
flutter devices
flutter run -d chrome
```

You can replace `chrome` with another device ID shown by `flutter devices`, or
run `flutter run` to select a target interactively. For a production web build:

```powershell
flutter build web
```

Start the FastAPI backend separately before requesting routes. From the
repository's `backend` directory, run:

```powershell
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

Keep that terminal open while using the app. Flutter web connects to
`http://127.0.0.1:8000`; Android emulators use `http://10.0.2.2:8000` to reach
the backend on the host machine. If the route panel says FastAPI is not
responding, the backend process is not listening on port 8000.

## Using the map

1. Allow location access or enable simulation mode.
2. Type a place or address in the destination search box and choose a result.
3. Select the Safe or Direct route, then start navigation.
4. Follow the map and spoken turn instructions. The selected route remains
   fixed during navigation.
5. At the destination, confirm arrival or choose another map point.

Destination search uses Photon with typo-tolerant OpenStreetMap geocoding.
Selected places are saved locally and shown as recent searches; new users see
no suggested places until they have selected a destination. Safe-haven markers
are loaded from `assets/mock_data/real_havens_petaling_jaya.geojson`. Route data
comes from the FastAPI backend. The map uses OpenStreetMap tiles and displays
contributor attribution.
