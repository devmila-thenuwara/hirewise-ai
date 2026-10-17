import from jaclang.byllm.lib { Model }

glob llm: Model = Model(model_name="gemini/gemini-3.8-flash");

node Zone { has name: str = "", x: float = 0.0, y: float = 0.0, region: str = "", demand_morning: float = 0.5, demand_midday: float = 0.5, demand_evening: float = 0.5; }
node RoadLink { has origin: str = "", destination: str = "", distance_km: float = 0.0, traffic_morning: float = 1.0, traffic_midday: float = 1.0, traffic_evening: float = 1.0; }
node DriverSetup { has goals_text: str = "", region: str = "Sri Lanka", currency: str = "LKR", distance_unit: str = "km", time_zone: str = "Asia/Colombo", start_zone: str = "Moratuwa", home_zone: str = "Moratuwa", shift_hours: float = 4.0, target_profit: float = 4500.0, deadline: str = "13:00", preference: str = "profit", vehicle_type: str = "petrol", fuel_efficiency: float = 12.0, fuel_price: float = 350.0, ev_efficiency: float = 7.0, electricity_price: float = 60.0; }
node SimOffer { has pickup: str = "", dropoff: str = "", fare: float = 0.0, distance_km: float = 0.0, duration_min: float = 0.0, pickup_km: float = 0.0, surge: float = 0.0, status: str = "available"; }
node DecisionRecord { has offer_id: str = "", decision: str = "", amount: float = 0.0, minutes: float = 0.0, destination: str = ""; }

obj GoalDraft { has start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str; }
obj ZoneView { has name: str, x: float, y: float, region: str, demand_morning: float, demand_midday: float, demand_evening: float; }
obj EvaluationView { has trip_net: float, return_value: float, empty_return_cost: float, home_eta: float, deadline_feasible: bool, recommendation: str, reason: str, cost_km: float, trip_cost: float, demand: float, traffic_eta: float; }
obj OfferView { has id: str, pickup: str, dropoff: str, fare: float, distance_km: float, duration_min: float, pickup_km: float, surge: float, status: str, evaluation: EvaluationView; }
obj SetupView { has goals_text: str, region: str, currency: str, distance_unit: str, time_zone: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float; }
obj DecisionView { has offer_id: str, decision: str, amount: float, minutes: float, destination: str; }
obj WorkspaceView { has setup: SetupView, zones: list[ZoneView], offers: list[OfferView], decisions: list[DecisionView], tracked_zone: str; }
obj ShiftComparisonView { has naive_profit: float, naive_minutes: float, naive_home_eta: float, naive_location: str, naive_taken: list[str], agent_profit: float, agent_minutes: float, agent_home_eta: float, agent_location: str, agent_taken: list[str], deadline_minutes: float; }

sem GoalDraft.start_zone = "A simulated zone in Sri Lanka.";
sem GoalDraft.home_zone = "The driver's simulated home zone.";
sem GoalDraft.shift_hours = "Requested duration in hours.";
sem GoalDraft.target_profit = "Net profit goal in simulated currency.";
sem GoalDraft.deadline = "Home deadline in 24-hour HH:MM format.";
def parseGoals(text: str) -> GoalDraft by llm(temperature=0.1, max_tokens=300);
sem parseGoals = "Parse a driver's shift request. Default to a four-hour shift, 4500 net target and 13:00 deadline. Use Sri Lankan zones if no specific zone is provided. All trip and cost values are simulated.";
sem parseGoals.text = "Natural-language driver shift goal.";
def:pub getOfferExplanation(offer_text: str, evaluation_text: str) -> str by llm(temperature=0.3, max_tokens=100);
sem getOfferExplanation = "Briefly explain simulated trip economics and the deterministic recommendation. Do not invent data or claim live traffic accuracy.";
sem getOfferExplanation.offer_text = "Simulated offer details.";
sem getOfferExplanation.evaluation_text = "Deterministic evaluation.";

# Idempotently populate the shared simulated catalog for all regions.
def _ensure_workspace() {
    if len([root -->][?:DriverSetup]) == 0 { root ++> DriverSetup(); }
    if len([root -->][?:Zone]) == 0 {
        root ++> Zone(name="Moratuwa", x=16.0, y=66.0, region="Sri Lanka", demand_morning=0.72, demand_midday=0.58, demand_evening=0.66);
        root ++> Zone(name="Colombo Fort", x=43.0, y=47.0, region="Sri Lanka", demand_morning=0.84, demand_midday=0.78, demand_evening=0.82);
        root ++> Zone(name="Dehiwala", x=33.0, y=62.0, region="Sri Lanka", demand_morning=0.70, demand_midday=0.61, demand_evening=0.68);
        root ++> Zone(name="Nugegoda", x=40.0, y=59.0, region="Sri Lanka", demand_morning=0.73, demand_midday=0.65, demand_evening=0.71);
        root ++> Zone(name="Maharagama", x=48.0, y=67.0, region="Sri Lanka", demand_morning=0.59, demand_midday=0.51, demand_evening=0.60);
        root ++> Zone(name="Negombo", x=39.0, y=20.0, region="Sri Lanka", demand_morning=0.63, demand_midday=0.57, demand_evening=0.55);
        root ++> Zone(name="Galle", x=22.0, y=92.0, region="Sri Lanka", demand_morning=0.55, demand_midday=0.62, demand_evening=0.58);
        root ++> Zone(name="Kandy", x=78.0, y=45.0, region="Sri Lanka", demand_morning=0.66, demand_midday=0.64, demand_evening=0.60);
        root ++> Zone(name="London", x=27.0, y=45.0, region="United Kingdom", demand_morning=0.76, demand_midday=0.68, demand_evening=0.74);
        root ++> Zone(name="Manchester", x=31.0, y=27.0, region="United Kingdom", demand_morning=0.69, demand_midday=0.61, demand_evening=0.67);
        root ++> Zone(name="Birmingham", x=35.0, y=36.0, region="United Kingdom", demand_morning=0.65, demand_midday=0.60, demand_evening=0.64);
        root ++> Zone(name="Edinburgh", x=36.0, y=12.0, region="United Kingdom", demand_morning=0.62, demand_midday=0.58, demand_evening=0.61);
        root ++> Zone(name="New York", x=65.0, y=37.0, region="United States", demand_morning=0.82, demand_midday=0.70, demand_evening=0.85);
        root ++> Zone(name="Chicago", x=57.0, y=31.0, region="United States", demand_morning=0.70, demand_midday=0.63, demand_evening=0.72);
        root ++> Zone(name="Los Angeles", x=48.0, y=57.0, region="United States", demand_morning=0.77, demand_midday=0.66, demand_evening=0.79);
        root ++> Zone(name="Austin", x=59.0, y=51.0, region="United States", demand_morning=0.65, demand_midday=0.62, demand_evening=0.71);
    }
    if len([root -->][?:RoadLink]) == 0 {
        root ++> RoadLink(origin="Moratuwa", destination="Colombo Fort", distance_km=20.0, traffic_morning=1.55, traffic_midday=1.12, traffic_evening=1.62);
        root ++> RoadLink(origin="Moratuwa", destination="Dehiwala", distance_km=8.0, traffic_morning=1.38, traffic_midday=1.08, traffic_evening=1.42);
        root ++> RoadLink(origin="Dehiwala", destination="Nugegoda", distance_km=7.0, traffic_morning=1.28, traffic_midday=1.05, traffic_evening=1.34);
        root ++> RoadLink(origin="Colombo Fort", destination="Negombo", distance_km=38.0, traffic_morning=1.45, traffic_midday=1.12, traffic_evening=1.48);
        root ++> RoadLink(origin="Moratuwa", destination="Galle", distance_km=105.0, traffic_morning=1.18, traffic_midday=1.08, traffic_evening=1.22);
        root ++> RoadLink(origin="Colombo Fort", destination="Kandy", distance_km=118.0, traffic_morning=1.42, traffic_midday=1.15, traffic_evening=1.52);
        root ++> RoadLink(origin="London", destination="Birmingham", distance_km=202.0, traffic_morning=1.52, traffic_midday=1.17, traffic_evening=1.60);
        root ++> RoadLink(origin="London", destination="Manchester", distance_km=336.0, traffic_morning=1.40, traffic_midday=1.12, traffic_evening=1.48);
        root ++> RoadLink(origin="Birmingham", destination="Manchester", distance_km=140.0, traffic_morning=1.35, traffic_midday=1.10, traffic_evening=1.42);
        root ++> RoadLink(origin="New York", destination="Chicago", distance_km=1270.0, traffic_morning=1.55, traffic_midday=1.18, traffic_evening=1.62);
        root ++> RoadLink(origin="Los Angeles", destination="Austin", distance_km=1960.0, traffic_morning=1.40, traffic_midday=1.12, traffic_evening=1.50);
        root ++> RoadLink(origin="Chicago", destination="New York", distance_km=1270.0, traffic_morning=1.55, traffic_midday=1.18, traffic_evening=1.62);
    }
    offers: list[SimOffer] = [];
    if len([root -->][?:SimOffer]) == 0 {
        offers = [SimOffer(pickup="Moratuwa", dropoff="Colombo Fort", fare=2400.0, distance_km=20.0, duration_min=52.0, pickup_km=2.0, surge=300.0), SimOffer(pickup="Colombo Fort", dropoff="Negombo", fare=6400.0, distance_km=38.0, duration_min=76.0, pickup_km=4.0), SimOffer(pickup="Dehiwala", dropoff="Nugegoda", fare=1450.0, distance_km=7.0, duration_min=25.0, pickup_km=1.0), SimOffer(pickup="Moratuwa", dropoff="Galle", fare=14800.0, distance_km=105.0, duration_min=145.0, pickup_km=5.0, surge=1800.0), SimOffer(pickup="London", dropoff="Birmingham", fare=86.0, distance_km=202.0, duration_min=150.0, pickup_km=3.0, surge=8.0), SimOffer(pickup="London", dropoff="Manchester", fare=142.0, distance_km=336.0, duration_min=220.0, pickup_km=4.0), SimOffer(pickup="Birmingham", dropoff="Manchester", fare=62.0, distance_km=140.0, duration_min=105.0, pickup_km=2.0), SimOffer(pickup="New York", dropoff="Chicago", fare=190.0, distance_km=1270.0, duration_min=115.0, pickup_km=5.0, surge=24.0), SimOffer(pickup="Los Angeles", dropoff="Austin", fare=260.0, distance_km=1960.0, duration_min=175.0, pickup_km=8.0), SimOffer(pickup="Chicago", dropoff="New York", fare=188.0, distance_km=1270.0, duration_min=118.0, pickup_km=3.0, surge=18.0)];
        for offer in offers { root ++> offer; }
    }
}

# Units are held in km and converted to display miles for UK/USA. Fare/energy values are illustrative.
def _region_settings(region: str) -> dict {
    if region == "United Kingdom" { return {"currency": "GBP", "distance_unit": "miles", "time_zone": "Europe/London", "start": "London", "fuel": 1.55, "electricity": 0.28}; }
    elif region == "United States" { return {"currency": "USD", "distance_unit": "miles", "time_zone": "America/New_York", "start": "New York", "fuel": 3.60, "electricity": 0.16}; }
    return {"currency": "LKR", "distance_unit": "km", "time_zone": "Asia/Colombo", "start": "Moratuwa", "fuel": 350.0, "electricity": 60.0};
}

def _zone_demand(zones: list[Zone], name: str) -> float {
    for z in zones { if z.name == name { return (z.demand_morning + z.demand_midday + z.demand_evening) / 3.0; } }
    return 0.5;
}
def _vehicle_cost(setup: DriverSetup) -> float {
    return setup.electricity_price / setup.ev_efficiency if setup.vehicle_type == "ev" else setup.fuel_price / setup.fuel_efficiency;
}
def _minutes_to_deadline(deadline: str, shift_hours: float) -> float {
    bits = deadline.split(":");
    if len(bits) != 2 { return shift_hours * 60.0; }
    try { remaining = int(bits[0]) * 60 + int(bits[1]) - 540; return float(remaining + 1440 if remaining < 0 else remaining); }
    except ValueError { return shift_hours * 60.0; }
}
def _offer_metrics(offer: dict, setup: DriverSetup, zones: list[Zone]) -> dict {
    cost = _vehicle_cost(setup);
    distance = offer["distance_km"] as float;
    fare = offer["fare"] as float;
    duration = (offer["duration_min"] as float) * 1.25;
    trip_cost = (distance + (offer["pickup_km"] as float)) * cost;
    net = fare - trip_cost;
    demand = _zone_demand(zones, offer["dropoff"] as str);
    empty_cost = distance * 0.75 * cost;
    return_value = demand * fare * 0.55;
    home_eta = duration + distance * 1.6;
    feasible = home_eta <= _minutes_to_deadline(setup.deadline, setup.shift_hours);
    recommendation = "ACCEPT";
    reason = "Positive simulated trip net and deadline is feasible.";
    if not feasible { recommendation = "DECLINE"; reason = "This route would make the simulated home deadline infeasible."; }
    elif net + return_value < empty_cost { recommendation = "WAIT"; reason = "Reposition toward a higher simulated demand zone while waiting."; }
    elif net < empty_cost * 0.35 { recommendation = "WAIT"; reason = "Net is modest after energy cost; reposition toward higher simulated demand."; }
    elif setup.preference == "route" { reason = "Your priority is shortest ETA; compare fare and net before deciding."; }
    return {"trip_net": net, "return_value": return_value, "empty_return_cost": empty_cost, "home_eta": home_eta, "deadline_feasible": feasible, "recommendation": recommendation, "reason": reason, "cost_km": cost, "trip_cost": trip_cost, "demand": demand, "traffic_eta": duration};
}

def:pub parseGoals(text: str) -> GoalDraft by llm(temperature=0.1, max_tokens=300);
sem parseGoals = "Parse a driver's shift request. The specified region's workspace controls currency and units. Default 4 hours, 4500 net target, 13:00 deadline. All offers and values are simulated.";
sem parseGoals.text = "Natural-language driver shift goal.";
def:pub getOfferExplanation(offer_text: str, evaluation_text: str) -> str by llm(temperature=0.3, max_tokens=100);
sem getOfferExplanation = "Briefly explain simulated trip economics and deterministic recommendation. Never claim live driver tracking or traffic prediction.";
sem getOfferExplanation.offer_text = "Simulated offer details.";
sem getOfferExplanation.evaluation_text = "Deterministic evaluation.";

def:pub getDriverWorkspace() -> WorkspaceView {
    _ensure_workspace();
    setup = [root -->][?:DriverSetup][0];
    zones_all = [root -->][?:Zone];
    region_zones: list[Zone] = [z for z in zones_all if z.region == setup.region];
    decisions = [root -->][?:DecisionRecord];
    tracked = setup.start_zone;
    for d in decisions { if d.decision == "accept" { tracked = d.destination; } }
    setup_view = SetupView(goals_text=setup.goals_text, region=setup.region, currency=setup.currency, distance_unit=setup.distance_unit, time_zone=setup.time_zone, start_zone=setup.start_zone, home_zone=setup.home_zone, shift_hours=setup.shift_hours, target_profit=setup.target_profit, deadline=setup.deadline, preference=setup.preference, vehicle_type=setup.vehicle_type, fuel_efficiency=setup.fuel_efficiency, fuel_price=setup.fuel_price, ev_efficiency=setup.ev_efficiency, electricity_price=setup.electricity_price);
    zone_views: list[ZoneView] = [ZoneView(name=z.name, x=z.x, y=z.y, region=z.region, demand_morning=z.demand_morning, demand_midday=z.demand_midday, demand_evening=z.demand_evening) for z in region_zones];
    offer_views: list[OfferView] = [];
    for o in [root -->][?:SimOffer] {
        pickup_region = "Sri Lanka";
        drop_region = "Sri Lanka";
        for z in zones_all { if z.name == o.pickup { pickup_region = z.region; } if z.name == o.dropoff { drop_region = z.region; } }
        if pickup_region == setup.region and drop_region == setup.region {
            raw = {"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km};
            metrics = _offer_metrics(raw, setup, zones_all);
            evaluation = EvaluationView(trip_net=metrics["trip_net"] as float, return_value=metrics["return_value"] as float, empty_return_cost=metrics["empty_return_cost"] as float, home_eta=metrics["home_eta"] as float, deadline_feasible=metrics["deadline_feasible"] as bool, recommendation=metrics["recommendation"] as str, reason=metrics["reason"] as str, cost_km=metrics["cost_km"] as float, trip_cost=metrics["trip_cost"] as float, demand=metrics["demand"] as float, traffic_eta=metrics["traffic_eta"] as float);
            offer_views.append(OfferView(id=jid(o), pickup=o.pickup, dropoff=o.dropoff, fare=o.fare, distance_km=o.distance_km, duration_min=o.duration_min, pickup_km=o.pickup_km, surge=o.surge, status=o.status, evaluation=evaluation));
        }
    }
    decision_views: list[DecisionView] = [DecisionView(offer_id=d.offer_id, decision=d.decision, amount=d.amount, minutes=d.minutes, destination=d.destination) for d in decisions];
    return WorkspaceView(setup=setup_view, zones=zone_views, offers=offer_views, decisions=decision_views, tracked_zone=tracked);
}

def:pub saveDriverSetup(region: str, goals_text: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float) -> dict {
    _ensure_workspace();
    if shift_hours <= 0.0 or target_profit < 0.0 or fuel_efficiency <= 0.0 or fuel_price < 0.0 or ev_efficiency <= 0.0 or electricity_price < 0.0 { return {"ok": False, "error": "Enter valid positive shift and efficiency, and non-negative target and energy prices."}; }
    if region != "Sri Lanka" and region != "United Kingdom" and region != "United States" { return {"ok": False, "error": "Choose a supported region."}; }
    setup = [root -->][?:DriverSetup][0];
    settings = _region_settings(region);
    setup.region = region; setup.currency = settings["currency"] as str; setup.distance_unit = settings["distance_unit"] as str; setup.time_zone = settings["time_zone"] as str;
    setup.goals_text = goals_text;
    setup.start_zone = start_zone if start_zone != "" else settings["start"] as str;
    setup.home_zone = home_zone if home_zone != "" else setup.start_zone;
    setup.shift_hours = shift_hours; setup.target_profit = target_profit; setup.deadline = deadline; setup.preference = "route" if preference == "route" else "profit"; setup.vehicle_type = "ev" if vehicle_type == "ev" else "petrol";
    setup.fuel_efficiency = fuel_efficiency; setup.fuel_price = fuel_price; setup.ev_efficiency = ev_efficiency; setup.electricity_price = electricity_price;
    return {"ok": True};
}

def:pub decideOffer(offer_id: str, decision: str) -> dict {
    _ensure_workspace();
    if decision != "accept" and decision != "decline" { return {"ok": False, "error": "Choose accept or decline."}; }
    setup = [root -->][?:DriverSetup][0];
    zones = [root -->][?:Zone];
    for offer in [root -->][?:SimOffer] {
        if jid(offer) == offer_id and offer.status == "available" {
            pickup_region = ""; drop_region = "";
            for z in zones { if z.name == offer.pickup { pickup_region = z.region; } if z.name == offer.dropoff { drop_region = z.region; } }
            if pickup_region != setup.region or drop_region != setup.region { return {"ok": False, "error": "Offer is outside the selected region."}; }
            metrics = _offer_metrics({"id": jid(offer), "pickup": offer.pickup, "dropoff": offer.dropoff, "fare": offer.fare + offer.surge, "distance_km": offer.distance_km, "duration_min": offer.duration_min, "pickup_km": offer.pickup_km}, setup, zones);
            if decision == "accept" and not (metrics["deadline_feasible"] as bool) { return {"ok": False, "error": "Offer would make the configured deadline infeasible."}; }
            offer.status = "accepted" if decision == "accept" else "declined";
            root ++> DecisionRecord(offer_id=offer_id, decision=decision, amount=metrics["trip_net"] as float, minutes=metrics["traffic_eta"] as float, destination=offer.dropoff);
            return {"ok": True};
        }
    }
    return {"ok": False, "error": "Offer is no longer available."};
}

def:pub getShiftComparison() -> ShiftComparisonView {
    _ensure_workspace();
    setup = [root -->][?:DriverSetup][0];
    zones = [root -->][?:Zone];
    records: list[dict] = [];
    for offer in [root -->][?:SimOffer] {
        pickup_region = ""; drop_region = "";
        for z in zones { if z.name == offer.pickup { pickup_region = z.region; } if z.name == offer.dropoff { drop_region = z.region; } }
        if pickup_region == setup.region and drop_region == setup.region { records.append({"id": jid(offer), "pickup": offer.pickup, "dropoff": offer.dropoff, "fare": offer.fare + offer.surge, "distance_km": offer.distance_km, "duration_min": offer.duration_min, "pickup_km": offer.pickup_km}); }
    }
    deadline = _minutes_to_deadline(setup.deadline, setup.shift_hours); cost = _vehicle_cost(setup);
    naive_profit = 0.0; naive_minutes = 0.0; naive_location = setup.start_zone; naive_taken: list[str] = [];
    remaining = [row for row in records];
    while len(remaining) > 0 {
        best = remaining[0];
        for row in remaining { if (row["fare"] as float) > (best["fare"] as float) { best = row; } }
        remaining.remove(best);
        duration = (best["duration_min"] as float) * 1.25; return_mins = (best["distance_km"] as float) * 1.6;
        if naive_minutes + duration + return_mins <= deadline { naive_minutes += duration; naive_profit += (best["fare"] as float) - ((best["distance_km"] as float) + (best["pickup_km"] as float)) * cost; naive_location = best["dropoff"] as str; naive_taken.append(best["id"] as str); }
    }
    agent_profit = 0.0; agent_minutes = 0.0; agent_location = setup.start_zone; agent_taken: list[str] = [];
    for row in records {
        metrics = _offer_metrics(row, setup, zones);
        if (metrics["recommendation"] as str) == "ACCEPT" and agent_minutes + (metrics["traffic_eta"] as float) + (row["distance_km"] as float) * 1.6 <= deadline { agent_profit += metrics["trip_net"] as float; agent_minutes += metrics["traffic_eta"] as float; agent_location = row["dropoff"] as str; agent_taken.append(row["id"] as str); }
    }
    return ShiftComparisonView(naive_profit=naive_profit, naive_minutes=naive_minutes, naive_home_eta=naive_minutes + 32.0, naive_location=naive_location, naive_taken=naive_taken, agent_profit=agent_profit, agent_minutes=agent_minutes, agent_home_eta=agent_minutes + 32.0, agent_location=agent_location, agent_taken=agent_taken, deadline_minutes=deadline);
}
