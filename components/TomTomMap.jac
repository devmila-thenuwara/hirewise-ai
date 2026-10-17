import from "@tomtom-international/web-sdk-maps" { default as tt }
import "@tomtom-international/web-sdk-maps/dist/maps.css";

glob mapInstance: any = None;
glob mapHost: any = None;
glob fallbackCallback: any = None;
glob centerValue: list[float] = [];
glob zoomValue: float = 0.0;

# TomTom map with optional device location control. Zone and offer data remain simulated.
def:pub TomTomMap(host: any, center: list[float], zoom: float, onFallback: Callable[[str], None]) -> JsxElement {
    can with (host, center, zoom, onFallback) entry {
        mapHost = host.current;
        centerValue = center;
        zoomValue = zoom;
        fallbackCallback = onFallback;
        if mapHost and globalThis.__TOMTOM_API_KEY__ {
            try {
                mapInstance = tt.map({"key": globalThis.__TOMTOM_API_KEY__, "container": mapHost, "center": centerValue, "zoom": zoomValue, "style": {"map": "basic_main", "trafficFlow": "flow_relative", "trafficIncidents": "incidents_day"}, "interactive": True});
                mapInstance.addControl(new(tt.NavigationControl), "top-right");
                mapInstance.addControl(new(tt.GeolocateControl, {"positionOptions": {"enableHighAccuracy": True}, "trackUserLocation": True, "showUserLocation": True}), "top-right");
                mapInstance.on("error", lambda (event: any) { if fallbackCallback { fallbackCallback.call(None, "TomTom map is unavailable; the simulated zone list remains available."); } });
            } except Exception {
                if fallbackCallback { fallbackCallback.call(None, "TomTom map could not load; the simulated zone list remains available."); }
            }
        } elif not globalThis.__TOMTOM_API_KEY__ {
            if fallbackCallback { fallbackCallback.call(None, "Add MAPS_API_KEYS in Settings to enable the map. Device location is available from the map control."); }
        }
    }

    can with (center, zoom) entry {
        if mapInstance { mapInstance.setCenter(center); mapInstance.setZoom(zoom); }
    }

    can with exit {
        if mapInstance { mapInstance.remove(); mapInstance = None; }
        mapHost = None;
    }
    return <div ref={host} className="h-full min-h-[280px] w-full overflow-hidden rounded-xl" aria-label="TomTom map with opt-in device location control" />;
}
