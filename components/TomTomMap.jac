import from "@tomtom-international/web-sdk-maps" { default as tt }
import "@tomtom-international/web-sdk-maps/dist/maps.css";

# TomTom Maps SDK JavaScript: map, default live traffic-flow layer, and simulated position marker.
def:pub TomTomMap(host: any, mapCenter: list[float], zoom: float, trafficEnabled: bool, onFallback: Callable[[str], None]) -> JsxElement {
    glob mapInstance: any = None;
    glob markerInstance: any = None;
    glob mapHost: any = None;
    glob mapCenterValue: list[float] = [];
    glob zoomValue: float = 0.0;
    glob trafficValue: bool = False;
    glob fallbackCallback: any = None;

    can with (host, mapCenter, zoom, trafficEnabled, onFallback) entry {
        mapHost = host.current;
        mapCenterValue = mapCenter;
        zoomValue = zoom;
        trafficValue = trafficEnabled;
        fallbackCallback = onFallback;
        if mapHost and globalThis.__TOMTOM_API_KEY__ {
            try {
                mapInstance = tt.map({
                    "key": globalThis.__TOMTOM_API_KEY__,
                    "container": mapHost,
                    "center": mapCenterValue,
                    "zoom": zoomValue,
                    "style": {"map": "basic_main", "trafficIncidents": "incidents_day", "trafficFlow": "flow_relative", "poi": "poi_main"},
                    "stylesVisibility": {"trafficFlow": trafficValue, "trafficIncidents": trafficValue},
                    "scrollZoom": False,
                    "interactive": True
                });
                markerInstance = new(tt.Marker, {"color": "#f97316", "width": "18px", "height": "18px"});
                markerInstance.setLngLat(mapCenterValue).addTo(mapInstance);
                mapInstance.on("error", lambda (errorEvent: any) {
                    if fallbackCallback { fallbackCallback.call(None, "TomTom map failed; showing the simulated zone diagram."); }
                });
            } except Exception {
                if fallbackCallback { fallbackCallback.call(None, "TomTom map could not load; showing the simulated zone diagram."); }
            }
        } elif not globalThis.__TOMTOM_API_KEY__ {
            if fallbackCallback { fallbackCallback.call(None, "TOMTOM_API_KEY is missing; showing the simulated zone diagram."); }
        }
    }

    can with (mapCenter, zoom, trafficEnabled) entry {
        if mapInstance {
            mapInstance.setCenter(mapCenter);
            mapInstance.setZoom(zoom);
            if trafficEnabled { mapInstance.showTrafficFlow(); mapInstance.showTrafficIncidents(); }
            else { mapInstance.hideTrafficFlow(); mapInstance.hideTrafficIncidents(); }
            if markerInstance { markerInstance.setLngLat(mapCenter); }
        }
    }

    can with exit {
        if markerInstance { markerInstance.remove(); markerInstance = None; }
        if mapInstance { mapInstance.remove(); mapInstance = None; }
        mapHost = None;
    }

    return <div ref={host} className="h-full min-h-[320px] w-full overflow-hidden rounded-xl" aria-label="TomTom map showing live traffic and simulated driver position" />;
}
