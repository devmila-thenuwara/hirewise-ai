import from "@tomtom-international/web-sdk-maps" { default as ttMaps }
import from "@tomtom-international/web-sdk-services" { default as ttServices }

glob mapInstance: any = None;
glob mapMarker: any = None;

def createTomTomMap(host: any, key: str, center: list[float], zoom: int, traffic: bool) -> any {
    map = ttMaps.map({"key": key, "container": host, "center": center, "zoom": zoom, "style": {"map": "basic_main", "trafficIncidents": "incidents_day", "trafficFlow": "flow_relative", "poi": "poi_main"}, "stylesVisibility": {"trafficFlow": traffic, "trafficIncidents": traffic}, "scrollZoom": False, "interactive": True});
    mapInstance = map;
    return map;
}

def addSimulatedMarker(center: list[float]) {
    if mapInstance {
        if mapMarker { mapMarker.remove(); }
        mapMarker = new(ttMaps.Marker, {"color": "#f97316", "width": "18px", "height": "18px"});
        mapMarker.setLngLat(center).addTo(mapInstance);
    }
}

async def resolveTomTomRoute(key: str, origin: str, destination: str, country_set: str) -> dict {
    try {
        origin_search = await ttServices.services.fuzzySearch({"key": key, "query": origin, "limit": 1, "countrySet": country_set});
        destination_search = await ttServices.services.fuzzySearch({"key": key, "query": destination, "limit": 1, "countrySet": country_set});
        if not origin_search or len(origin_search.results) == 0 or not destination_search or len(destination_search.results) == 0 { return {"ok": False, "error": "TomTom could not locate one of the selected zones."}; }
        origin_position = origin_search.results[0].position;
        destination_position = destination_search.results[0].position;
        locations = str(origin_position.lon) + "," + str(origin_position.lat) + ":" + str(destination_position.lon) + "," + str(destination_position.lat);
        route_response = await ttServices.services.calculateRoute({"key": key, "locations": locations, "routeType": "fastest", "traffic": True, "computeTravelTimeFor": "all"});
        if not route_response or len(route_response.routes) == 0 { return {"ok": False, "error": "TomTom returned no route."}; }
        route = route_response.routes[0];
        line_points: list[list[float]] = [[point.lng, point.lat] for point in route.legs[0].points];
        return {"ok": True, "coordinates": line_points, "eta_seconds": route.summary.travelTimeInSeconds, "traffic_delay_seconds": route.summary.trafficDelayInSeconds, "distance_meters": route.summary.lengthInMeters};
    } except Exception { return {"ok": False, "error": "TomTom routing is unavailable; the simulated zone diagram remains available."}; }
}

def updateTomTomTraffic(visible: bool) {
    if mapInstance {
        if visible { mapInstance.showTrafficFlow(); mapInstance.showTrafficIncidents(); }
        else { mapInstance.hideTrafficFlow(); mapInstance.hideTrafficIncidents(); }
    }
}

def updateTomTomRoute(coordinates: list[list[float]]) {
    if not mapInstance or len(coordinates) == 0 { return; }
    if mapInstance.getSource("hirewise-route") { mapInstance.removeLayer("hirewise-route-line"); mapInstance.removeSource("hirewise-route"); }
    mapInstance.addSource("hirewise-route", {"type": "geojson", "data": {"type": "Feature", "geometry": {"type": "LineString", "coordinates": coordinates}, "properties": {}}});
    mapInstance.addLayer({"id": "hirewise-route-line", "type": "line", "source": "hirewise-route", "paint": {"line-color": "#0f766e", "line-width": 5, "line-opacity": 0.9}});
}

def updateTomTomView(center: list[float], zoom: int) {
    if mapInstance { mapInstance.setCenter(center); mapInstance.setZoom(zoom); addSimulatedMarker(center); }
}

def destroyTomTomMap() {
    if mapMarker { mapMarker.remove(); mapMarker = None; }
    if mapInstance { mapInstance.remove(); mapInstance = None; }
}
