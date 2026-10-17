import from jaclang.byllm.lib { Model }

glob llm: Model = Model(model_name="gemini/gemini-3.8-flash");

node Zone { has name: str = "", x: float = 0.0, y: float = 0.0, region: str = "", demand_morning: float = 0.5, demand_midday: float = 0.5, demand_evening: float = 0.5; }
node RoadLink { has origin: str = "", destination: str = "", distance_km: float = 0.0, traffic_morning: float = 1.0, traffic_midday: float = 1.0, traffic_evening: float = 1.0; }
node DriverSetup { has goals_text: str = "", start_zone: str = "Moratuwa", home_zone: str = "Moratuwa", shift_hours: float = 4.0, target_profit: float = 4500.0, deadline: str = "13:00", preference: str = "profit", vehicle_type: str = "petrol", fuel_efficiency: float = 12.0, fuel_price: float = 350.0, ev_efficiency: float = 7.0, electricity_price: float = 60.0; }
node SimOffer { has pickup: str = "", dropoff: str = "", fare: float = 0.0, distance_km: float = 0.0, duration_min: float = 0.0, pickup_km: float = 0.0, surge: float = 0.0, status: str = "available"; }
node DecisionRecord { has offer_id: str = "", decision: str = "", amount: float = 0.0, minutes: float = 0.0, destination: str = ""; }

obj GoalDraft { has start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str; }
obj ZoneView { has name: str, x: float, y: float, region: str, demand_morning: float, demand_midday: float, demand_evening: float; }
obj EvaluationView { has trip_net: float, return_value: float, empty_return_cost: float, home_eta: float, deadline_feasible: bool, recommendation: str, reason: str, cost_km: float, trip_cost: float, demand: float, traffic_eta: float; }
obj OfferView { has id: str, pickup: str, dropoff: str, fare: float, distance_km: float, duration_min: float, pickup_km: float, surge: float, status: str, evaluation: EvaluationView; }
obj SetupView { has goals_text: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float; }
obj DecisionView { has offer_id: str, decision: str, amount: float, minutes: float, destination: str; }
obj WorkspaceView { has setup: SetupView, zones: list[ZoneView], offers: list[OfferView], decisions: list[DecisionView], tracked_zone: str; }
obj ShiftComparisonView { has naive_profit: float, naive_minutes: float, naive_home_eta: float, naive_location: str, naive_taken: list[str], agent_profit: float, agent_minutes: float, agent_home_eta: float, agent_location: str, agent_taken: list[str], deadline_minutes: float; }

sem GoalDraft.start_zone = "A Sri Lankan simulated district from the list.";
sem GoalDraft.home_zone = "The driver's simulated home district.";
sem GoalDraft.shift_hours = "Requested duration in hours.";
sem GoalDraft.target_profit = "Net profit goal in simulated rupees.";
sem GoalDraft.deadline = "Home deadline in 24-hour HH:MM format.";
def parseGoals(text: str) -> GoalDraft by llm(temperature=0.1, max_tokens=300);
sem parseGoals = "Parse a driver's shift request. Defaults: Moratuwa start/home, 4 hours, Rs 4500, deadline 13:00. Use Sri Lankan place names only. Data is simulated.";
sem parseGoals.text = "Natural-language driver shift goal.";

def _ensure_workspace() {
    if len([root -->][?:DriverSetup]) == 0 { root ++> DriverSetup(); }
    if len([root -->][?:Zone]) == 0 {
        root ++> Zone(name="Moratuwa", x=36.0, y=83.0, region="Western", demand_morning=0.71, demand_midday=0.64, demand_evening=0.69);
        root ++> Zone(name="Colombo Fort", x=37.0, y=69.0, region="Western", demand_morning=0.88, demand_midday=0.82, demand_evening=0.84);
        root ++> Zone(name="Dehiwala", x=39.0, y=78.0, region="Western", demand_morning=0.72, demand_midday=0.67, demand_evening=0.71);
        root ++> Zone(name="Nugegoda", x=41.0, y=73.0, region="Western", demand_morning=0.76, demand_midday=0.70, demand_evening=0.75);
        root ++> Zone(name="Maharagama", x=43.0, y=77.0, region="Western", demand_morning=0.67, demand_midday=0.63, demand_evening=0.68);
        root ++> Zone(name="Negombo", x=31.0, y=58.0, region="Western", demand_morning=0.68, demand_midday=0.65, demand_evening=0.63);
        root ++> Zone(name="Galle", x=44.0, y=91.0, region="Southern", demand_morning=0.70, demand_midday=0.74, demand_evening=0.68);
        root ++> Zone(name="Kandy", x=62.0, y=54.0, region="Central", demand_morning=0.72, demand_midday=0.68, demand_evening=0.64);
    }
    known: list[Zone] = [root -->][?:Zone];
    additions: list[Zone] = [Zone(name="Jaffna", x=57.0, y=10.0, region="Northern", demand_morning=0.62, demand_midday=0.60, demand_evening=0.56), Zone(name="Point Pedro", x=61.0, y=6.0, region="Northern", demand_morning=0.54, demand_midday=0.52, demand_evening=0.48), Zone(name="Kilinochchi", x=56.0, y=18.0, region="Northern", demand_morning=0.48, demand_midday=0.45, demand_evening=0.42), Zone(name="Mannar", x=39.0, y=24.0, region="Northern", demand_morning=0.50, demand_midday=0.52, demand_evening=0.46), Zone(name="Mullaitivu", x=70.0, y=21.0, region="Northern", demand_morning=0.42, demand_midday=0.40, demand_evening=0.38), Zone(name="Vavuniya", x=52.0, y=29.0, region="Northern", demand_morning=0.56, demand_midday=0.54, demand_evening=0.50), Zone(name="Trincomalee", x=79.0, y=31.0, region="Eastern", demand_morning=0.59, demand_midday=0.62, demand_evening=0.57), Zone(name="Anuradhapura", x=43.0, y=37.0, region="North Central", demand_morning=0.58, demand_midday=0.57, demand_evening=0.52), Zone(name="Puttalam", x=30.0, y=40.0, region="North Western", demand_morning=0.60, demand_midday=0.58, demand_evening=0.54), Zone(name="Polonnaruwa", x=64.0, y=41.0, region="North Central", demand_morning=0.52, demand_midday=0.53, demand_evening=0.49), Zone(name="Batticaloa", x=81.0, y=52.0, region="Eastern", demand_morning=0.63, demand_midday=0.64, demand_evening=0.58), Zone(name="Kurunegala", x=42.0, y=52.0, region="North Western", demand_morning=0.68, demand_midday=0.65, demand_evening=0.61), Zone(name="Matale", x=60.0, y=47.0, region="Central", demand_morning=0.56, demand_midday=0.55, demand_evening=0.51), Zone(name="Gampaha", x=36.0, y=61.0, region="Western", demand_morning=0.73, demand_midday=0.70, demand_evening=0.68), Zone(name="Ratnapura", x=51.0, y=75.0, region="Sabaragamuwa", demand_morning=0.61, demand_midday=0.59, demand_evening=0.54), Zone(name="Badulla", x=75.0, y=68.0, region="Uva", demand_morning=0.61, demand_midday=0.63, demand_evening=0.56), Zone(name="Nuwara Eliya", x=66.0, y=66.0, region="Central", demand_morning=0.56, demand_midday=0.61, demand_evening=0.52), Zone(name="Monaragala", x=79.0, y=73.0, region="Uva", demand_morning=0.48, demand_midday=0.51, demand_evening=0.45), Zone(name="Hambantota", x=70.0, y=91.0, region="Southern", demand_morning=0.58, demand_midday=0.62, demand_evening=0.56), Zone(name="Matara", x=53.0, y=93.0, region="Southern", demand_morning=0.65, demand_midday=0.68, demand_evening=0.62), Zone(name="Kalutara", x=34.0, y=88.0, region="Western", demand_morning=0.64, demand_midday=0.62, demand_evening=0.60), Zone(name="Ampara", x=84.0, y=63.0, region="Eastern", demand_morning=0.50, demand_midday=0.52, demand_evening=0.47), Zone(name="Kegalle", x=48.0, y=62.0, region="Sabaragamuwa", demand_morning=0.60, demand_midday=0.57, demand_evening=0.55), Zone(name="Chilaw", x=28.0, y=49.0, region="North Western", demand_morning=0.55, demand_midday=0.57, demand_evening=0.53)];
    for old_zone in known {
        for desired in additions {
            if old_zone.name == desired.name {
                old_zone.x = desired.x;
                old_zone.y = desired.y;
                old_zone.region = desired.region;
                old_zone.demand_morning = desired.demand_morning;
                old_zone.demand_midday = desired.demand_midday;
                old_zone.demand_evening = desired.demand_evening;
            }
        }
    }
    for fresh in additions {
        found = False;
        for old in known { if old.name == fresh.name { found = True; } }
        if not found { root ++> fresh; }
    }
    known = [root -->][?:Zone];
    links: list[RoadLink] = [RoadLink(origin="Jaffna", destination="Point Pedro", distance_km=32.0), RoadLink(origin="Jaffna", destination="Kilinochchi", distance_km=67.0), RoadLink(origin="Kilinochchi", destination="Vavuniya", distance_km=72.0), RoadLink(origin="Mannar", destination="Vavuniya", distance_km=96.0), RoadLink(origin="Vavuniya", destination="Anuradhapura", distance_km=55.0), RoadLink(origin="Vavuniya", destination="Trincomalee", distance_km=130.0), RoadLink(origin="Mullaitivu", destination="Trincomalee", distance_km=90.0), RoadLink(origin="Trincomalee", destination="Polonnaruwa", distance_km=110.0), RoadLink(origin="Anuradhapura", destination="Puttalam", distance_km=110.0), RoadLink(origin="Anuradhapura", destination="Kurunegala", distance_km=115.0), RoadLink(origin="Polonnaruwa", destination="Batticaloa", distance_km=110.0), RoadLink(origin="Polonnaruwa", destination="Matale", distance_km=85.0), RoadLink(origin="Kurunegala", destination="Kandy", distance_km=43.0), RoadLink(origin="Kurunegala", destination="Chilaw", distance_km=68.0), RoadLink(origin="Puttalam", destination="Chilaw", distance_km=42.0), RoadLink(origin="Chilaw", destination="Negombo", distance_km=55.0), RoadLink(origin="Negombo", destination="Gampaha", distance_km=40.0), RoadLink(origin="Gampaha", destination="Colombo Fort", distance_km=30.0), RoadLink(origin="Colombo Fort", destination="Nugegoda", distance_km=9.0), RoadLink(origin="Nugegoda", destination="Maharagama", distance_km=8.0), RoadLink(origin="Colombo Fort", destination="Dehiwala", distance_km=12.0), RoadLink(origin="Dehiwala", destination="Moratuwa", distance_km=8.0), RoadLink(origin="Moratuwa", destination="Kalutara", distance_km=34.0), RoadLink(origin="Kalutara", destination="Galle", distance_km=65.0), RoadLink(origin="Galle", destination="Matara", distance_km=45.0), RoadLink(origin="Matara", destination="Hambantota", distance_km=75.0), RoadLink(origin="Hambantota", destination="Monaragala", distance_km=100.0), RoadLink(origin="Monaragala", destination="Badulla", distance_km=70.0), RoadLink(origin="Badulla", destination="Nuwara Eliya", distance_km=55.0), RoadLink(origin="Nuwara Eliya", destination="Kandy", distance_km=75.0), RoadLink(origin="Kandy", destination="Matale", distance_km=28.0), RoadLink(origin="Kandy", destination="Kegalle", distance_km=70.0), RoadLink(origin="Kegalle", destination="Colombo Fort", distance_km=78.0), RoadLink(origin="Kegalle", destination="Ratnapura", distance_km=57.0), RoadLink(origin="Ratnapura", destination="Galle", distance_km=93.0), RoadLink(origin="Ratnapura", destination="Maharagama", distance_km=75.0), RoadLink(origin="Batticaloa", destination="Ampara", distance_km=65.0), RoadLink(origin="Ampara", destination="Monaragala", distance_km=88.0), RoadLink(origin="Matale", destination="Anuradhapura", distance_km=125.0)];
    existing_links: list[RoadLink] = [root -->][?:RoadLink];
    for link in links {
        found_link = False;
        for old_link in existing_links { if old_link.origin == link.origin and old_link.destination == link.destination { found_link = True; } }
        if not found_link { root ++> link; }
    }
    if len([root -->][?:SimOffer]) == 0 {
        root ++> SimOffer(pickup="Moratuwa", dropoff="Colombo Fort", fare=2400.0, distance_km=20.0, duration_min=52.0, pickup_km=2.0, surge=300.0);
        root ++> SimOffer(pickup="Colombo Fort", dropoff="Negombo", fare=6400.0, distance_km=38.0, duration_min=76.0, pickup_km=4.0);
        root ++> SimOffer(pickup="Dehiwala", dropoff="Nugegoda", fare=1450.0, distance_km=7.0, duration_min=25.0, pickup_km=1.0);
        root ++> SimOffer(pickup="Moratuwa", dropoff="Galle", fare=14800.0, distance_km=105.0, duration_min=145.0, pickup_km=5.0, surge=1800.0);
        root ++> SimOffer(pickup="Nugegoda", dropoff="Maharagama", fare=1600.0, distance_km=8.0, duration_min=28.0, pickup_km=1.0);
        root ++> SimOffer(pickup="Colombo Fort", dropoff="Kandy", fare=17800.0, distance_km=118.0, duration_min=190.0, pickup_km=6.0, surge=2400.0);
        root ++> SimOffer(pickup="Maharagama", dropoff="Galle", fare=15300.0, distance_km=110.0, duration_min=155.0, pickup_km=3.0);
        root ++> SimOffer(pickup="Dehiwala", dropoff="Colombo Fort", fare=2800.0, distance_km=12.0, duration_min=40.0, pickup_km=2.0, surge=450.0);
        root ++> SimOffer(pickup="Colombo Fort", dropoff="Nugegoda", fare=2150.0, distance_km=9.0, duration_min=31.0, pickup_km=1.0);
        root ++> SimOffer(pickup="Negombo", dropoff="Kandy", fare=16800.0, distance_km=112.0, duration_min=180.0, pickup_km=5.0, surge=1000.0);
        root ++> SimOffer(pickup="Jaffna", dropoff="Anuradhapura", fare=10400.0, distance_km=190.0, duration_min=220.0, pickup_km=5.0);
        root ++> SimOffer(pickup="Trincomalee", dropoff="Batticaloa", fare=7600.0, distance_km=110.0, duration_min=135.0, pickup_km=4.0);
        root ++> SimOffer(pickup="Kandy", dropoff="Badulla", fare=8900.0, distance_km=105.0, duration_min=165.0, pickup_km=3.0, surge=700.0);
        root ++> SimOffer(pickup="Galle", dropoff="Matara", fare=3900.0, distance_km=45.0, duration_min=64.0, pickup_km=2.0);
        root ++> SimOffer(pickup="Puttalam", dropoff="Kurunegala", fare=5200.0, distance_km=110.0, duration_min=145.0, pickup_km=4.0);
    }
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
    elif setup.preference == "route" { reason = "Your priority is shorter simulated ETA; compare fare and net before deciding."; }
    return {"trip_net": net, "return_value": return_value, "empty_return_cost": empty_cost, "home_eta": home_eta, "deadline_feasible": feasible, "recommendation": recommendation, "reason": reason, "cost_km": cost, "trip_cost": trip_cost, "demand": demand, "traffic_eta": duration};
}

def parseGoals(text: str) -> GoalDraft by llm(temperature=0.1, max_tokens=300);
sem parseGoals = "Parse a driver's shift request. Defaults: Moratuwa start/home, 4 hours, Rs 4500, deadline 13:00. Use Sri Lankan place names only. All data is simulated.";
sem parseGoals.text = "Natural-language driver shift goal.";
def:pub getOfferExplanation(offer_text: str, evaluation_text: str) -> str by llm(temperature=0.3, max_tokens=100);
sem getOfferExplanation = "Briefly explain these simulated trip economics and recommendation. Never invent numbers, recommend declining solely because of traffic, or encourage cancelling accepted rides.";
sem getOfferExplanation.offer_text = "Simulated offer details.";
sem getOfferExplanation.evaluation_text = "Deterministic evaluation.";

def:pub getDriverWorkspace() -> WorkspaceView {
    _ensure_workspace();
    setup = [root -->][?:DriverSetup][0];
    zones = [root -->][?:Zone];
    decisions = [root -->][?:DecisionRecord];
    tracked = setup.start_zone;
    for d in decisions { if d.decision == "accept" { tracked = d.destination; } }
    setup_view = SetupView(goals_text=setup.goals_text, start_zone=setup.start_zone, home_zone=setup.home_zone, shift_hours=setup.shift_hours, target_profit=setup.target_profit, deadline=setup.deadline, preference=setup.preference, vehicle_type=setup.vehicle_type, fuel_efficiency=setup.fuel_efficiency, fuel_price=setup.fuel_price, ev_efficiency=setup.ev_efficiency, electricity_price=setup.electricity_price);
    zone_views: list[ZoneView] = [ZoneView(name=z.name, x=z.x, y=z.y, region=z.region, demand_morning=z.demand_morning, demand_midday=z.demand_midday, demand_evening=z.demand_evening) for z in zones];
    offer_views: list[OfferView] = [];
    for o in [root -->][?:SimOffer] {
        raw = {"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km};
        m = _offer_metrics(raw, setup, zones);
        evaluation = EvaluationView(trip_net=m["trip_net"] as float, return_value=m["return_value"] as float, empty_return_cost=m["empty_return_cost"] as float, home_eta=m["home_eta"] as float, deadline_feasible=m["deadline_feasible"] as bool, recommendation=m["recommendation"] as str, reason=m["reason"] as str, cost_km=m["cost_km"] as float, trip_cost=m["trip_cost"] as float, demand=m["demand"] as float, traffic_eta=m["traffic_eta"] as float);
        offer_views.append(OfferView(id=jid(o), pickup=o.pickup, dropoff=o.dropoff, fare=o.fare, distance_km=o.distance_km, duration_min=o.duration_min, pickup_km=o.pickup_km, surge=o.surge, status=o.status, evaluation=evaluation));
    }
    decision_views: list[DecisionView] = [DecisionView(offer_id=d.offer_id, decision=d.decision, amount=d.amount, minutes=d.minutes, destination=d.destination) for d in decisions];
    return WorkspaceView(setup=setup_view, zones=zone_views, offers=offer_views, decisions=decision_views, tracked_zone=tracked);
}

def:pub saveDriverSetup(goals_text: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float) -> dict {
    _ensure_workspace();
    if shift_hours <= 0.0 or target_profit < 0.0 or fuel_efficiency <= 0.0 or fuel_price < 0.0 or ev_efficiency <= 0.0 or electricity_price < 0.0 { return {"ok": False, "error": "Enter valid positive shift and efficiency, and non-negative target and energy prices."}; }
    setup = [root -->][?:DriverSetup][0];
    setup.goals_text = goals_text; setup.start_zone = start_zone; setup.home_zone = home_zone; setup.shift_hours = shift_hours; setup.target_profit = target_profit; setup.deadline = deadline; setup.preference = "route" if preference == "route" else "profit"; setup.vehicle_type = "ev" if vehicle_type == "ev" else "petrol"; setup.fuel_efficiency = fuel_efficiency; setup.fuel_price = fuel_price; setup.ev_efficiency = ev_efficiency; setup.electricity_price = electricity_price;
    return {"ok": True};
}

def:pub decideOffer(offer_id: str, decision: str) -> dict {
    _ensure_workspace();
    if decision != "accept" and decision != "decline" { return {"ok": False, "error": "Choose accept or decline."}; }
    setup = [root -->][?:DriverSetup][0];
    zones = [root -->][?:Zone];
    for o in [root -->][?:SimOffer] {
        if jid(o) == offer_id and o.status == "available" {
            m = _offer_metrics({"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km}, setup, zones);
            if decision == "accept" and not (m["deadline_feasible"] as bool) { return {"ok": False, "error": "Offer would make the configured deadline infeasible."}; }
            o.status = "accepted" if decision == "accept" else "declined";
            root ++> DecisionRecord(offer_id=offer_id, decision=decision, amount=m["trip_net"] as float, minutes=m["traffic_eta"] as float, destination=o.dropoff);
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
    for o in [root -->][?:SimOffer] { records.append({"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km}); }
    deadline = _minutes_to_deadline(setup.deadline, setup.shift_hours);
    cost = _vehicle_cost(setup);
    naive_profit = 0.0; naive_minutes = 0.0; naive_location = setup.start_zone; naive_taken: list[str] = [];
    remaining = [r for r in records];
    while len(remaining) > 0 {
        best = remaining[0];
        for r in remaining { if (r["fare"] as float) > (best["fare"] as float) { best = r; } }
        remaining.remove(best);
        dur = (best["duration_min"] as float) * 1.25;
        back = (best["distance_km"] as float) * 1.6;
        if naive_minutes + dur + back <= deadline { naive_minutes += dur; naive_profit += (best["fare"] as float) - ((best["distance_km"] as float) + (best["pickup_km"] as float)) * cost; naive_location = best["dropoff"] as str; naive_taken.append(best["id"] as str); }
    }
    agent_profit = 0.0; agent_minutes = 0.0; agent_location = setup.start_zone; agent_taken: list[str] = [];
    for r in records {
        m = _offer_metrics(r, setup, zones);
        if (m["recommendation"] as str) == "ACCEPT" and agent_minutes + (m["traffic_eta"] as float) + (r["distance_km"] as float) * 1.6 <= deadline { agent_profit += m["trip_net"] as float; agent_minutes += m["traffic_eta"] as float; agent_location = r["dropoff"] as str; agent_taken.append(r["id"] as str); }
    }
    return ShiftComparisonView(naive_profit=naive_profit, naive_minutes=naive_minutes, naive_home_eta=naive_minutes + 32.0, naive_location=naive_location, naive_taken=naive_taken, agent_profit=agent_profit, agent_minutes=agent_minutes, agent_home_eta=agent_minutes + 32.0, agent_location=agent_location, agent_taken=agent_taken, deadline_minutes=deadline);
}
