import from jaclang.byllm.lib { Model }
import from .accountService { DriverProfile }

glob llm: Model = Model(model_name="gemini/gemini-3.8-flash");

node PassengerRideRequest {
    has pickup: str = "";
    has dropoff: str = "";
    has time_band: str = "midday";
    has distance_km: float = 0.0;
    has fare_lkr: float = 0.0;
    has eta_min: float = 0.0;
    has status: str = "requested";
}

obj PassengerRouteOption {
    has kind: str;
    has label: str;
    has fare_lkr: float;
    has distance_km: float;
    has eta_min: float;
    has explanation: str;
}

obj PassengerOptionsView {
    has pickup: str;
    has dropoff: str;
    has time_band: str;
    has options: list[PassengerRouteOption];
}

obj PassengerRequestView {
    has ok: bool;
    has message: str;
}

# Values below are explicitly illustrative route assumptions, not live TomTom routes or market fares.
def _zone_distance(pickup: str, dropoff: str) -> float {
    if pickup == dropoff { return 2.0; }
    if (pickup == "Moratuwa" and dropoff == "Colombo Fort") or (pickup == "Colombo Fort" and dropoff == "Moratuwa") { return 20.0; }
    if (pickup == "Moratuwa" and dropoff == "Dehiwala") or (pickup == "Dehiwala" and dropoff == "Moratuwa") { return 8.0; }
    if (pickup == "Dehiwala" and dropoff == "Nugegoda") or (pickup == "Nugegoda" and dropoff == "Dehiwala") { return 7.0; }
    if (pickup == "Colombo Fort" and dropoff == "Negombo") or (pickup == "Negombo" and dropoff == "Colombo Fort") { return 38.0; }
    if (pickup == "Moratuwa" and dropoff == "Galle") or (pickup == "Galle" and dropoff == "Moratuwa") { return 105.0; }
    if (pickup == "Colombo Fort" and dropoff == "Kandy") or (pickup == "Kandy" and dropoff == "Colombo Fort") { return 118.0; }
    return 18.0;
}

def _band_factor(time_band: str) -> float {
    if time_band == "morning" { return 1.45; }
    elif time_band == "evening" { return 1.5; }
    return 1.1;
}

def _valid_sri_lanka_zone(name: str) -> bool {
    return name == "Moratuwa" or name == "Colombo Fort" or name == "Dehiwala" or name == "Nugegoda" or name == "Maharagama" or name == "Negombo" or name == "Galle" or name == "Kandy";
}

def _passenger_role_ok() -> bool {
    profiles = [root -->][?:DriverProfile];
    return len(profiles) > 0 and profiles[0].role == "passenger";
}

def _request_origin_ok() -> bool {
    profiles = [root -->][?:DriverProfile];
    return len(profiles) > 0 and profiles[0].role == "driver";
}

sem passenger_explain = "Explain one simulated Sri Lankan route option in a single concise sentence. Do not claim live routing, live traffic, or market fare accuracy.";
sem passenger_explain.kind = "Route quality: fastest, cheapest, or least traffic.";
sem passenger_explain.details = "Simulated distance, ETA, fare, and time-band assumption.";
def passenger_explain(kind: str, details: str) -> str by llm(temperature=0.2, max_tokens=60);

async def:protect getPassengerOptions(pickup: str, dropoff: str, time_band: str) -> PassengerOptionsView {
    if not _passenger_role_ok() { raise ValueError("Passenger account required."); }
    if pickup == dropoff { raise ValueError("Choose different pickup and drop-off zones."); }
    if time_band != "morning" and time_band != "midday" and time_band != "evening" { raise ValueError("Choose a valid time band."); }
    valid_pickup = _valid_sri_lanka_zone(pickup);
    valid_dropoff = _valid_sri_lanka_zone(dropoff);
    if not valid_pickup or not valid_dropoff { raise ValueError("Choose Sri Lanka zones from the list."); }
    distance = _zone_distance(pickup, dropoff);
    traffic = _band_factor(time_band);
    fastest_eta = distance * traffic * 2.2;
    cheap_eta = fastest_eta * 1.22;
    low_eta = fastest_eta * 1.12;
    fastest_fare = 300.0 + distance * 125.0 * traffic;
    cheap_fare = fastest_fare * 0.88;
    low_fare = fastest_fare * 0.96;
    fastest_text = "fastest option; " + str(distance) + " km, " + str(round(fastest_eta)) + " simulated minutes, LKR " + str(round(fastest_fare)) + ", " + time_band + " factor " + str(traffic);
    cheap_text = "cheapest option; " + str(distance) + " km, " + str(round(cheap_eta)) + " simulated minutes, LKR " + str(round(cheap_fare)) + ", " + time_band + " factor " + str(traffic);
    low_text = "least-traffic option; " + str(distance) + " km, " + str(round(low_eta)) + " simulated minutes, LKR " + str(round(low_fare)) + ", " + time_band + " factor " + str(traffic);
    a = await passenger_explain("fastest", fastest_text);
    b = await passenger_explain("cheapest", cheap_text);
    c = await passenger_explain("least traffic", low_text);
    opts: list[PassengerRouteOption] = [PassengerRouteOption(kind="fastest", label="Fastest", fare_lkr=fastest_fare, distance_km=distance, eta_min=fastest_eta, explanation=a), PassengerRouteOption(kind="cheapest", label="Cheapest", fare_lkr=cheap_fare, distance_km=distance, eta_min=cheap_eta, explanation=b), PassengerRouteOption(kind="least_traffic", label="Least traffic", fare_lkr=low_fare, distance_km=distance, eta_min=low_eta, explanation=c)];
    return PassengerOptionsView(pickup=pickup, dropoff=dropoff, time_band=time_band, options=opts);
}

# Public request records reveal trip details only; no passenger identity or account fields are shared.
async def:protect createPassengerRequest(pickup: str, dropoff: str, time_band: str, option_kind: str) -> PassengerRequestView {
    if not _passenger_role_ok() { return PassengerRequestView(ok=False, message="Passenger account required."); }
    if pickup == dropoff { return PassengerRequestView(ok=False, message="Choose different pickup and drop-off zones."); }
    if time_band != "morning" and time_band != "midday" and time_band != "evening" { return PassengerRequestView(ok=False, message="Choose a valid time band."); }
    if option_kind != "fastest" and option_kind != "cheapest" and option_kind != "least_traffic" { return PassengerRequestView(ok=False, message="Choose a route option."); }
    valid_pickup = _valid_sri_lanka_zone(pickup);
    valid_dropoff = _valid_sri_lanka_zone(dropoff);
    if not valid_pickup or not valid_dropoff { return PassengerRequestView(ok=False, message="Choose Sri Lanka zones from the list."); }
    distance = _zone_distance(pickup, dropoff);
    traffic = _band_factor(time_band);
    multiplier = 1.0 if option_kind == "fastest" else (1.22 if option_kind == "cheapest" else 1.12);
    fare_multiplier = 1.0 if option_kind == "fastest" else (0.88 if option_kind == "cheapest" else 0.96);
    fare = (300.0 + distance * 125.0 * traffic) * fare_multiplier;
    eta = distance * traffic * 2.2 * multiplier;
    request = root.shared ++> PassengerRideRequest(pickup=pickup, dropoff=dropoff, time_band=time_band, distance_km=distance, fare_lkr=fare, eta_min=eta);
    grant(request, level=ReadPerm);
    return PassengerRequestView(ok=True, message="Simulated request sent to the driver feed. Fare and ETA are estimates.");
}

# Driver feed returns shared trip requests without passenger identity.
async def:protect getPassengerRequests() -> list[PassengerRideRequest] {
    if not _request_origin_ok() { return []; }
    return [r for r in [root.shared -->][?:PassengerRideRequest] if r.status == "requested"];
}
