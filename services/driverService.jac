import from jaclang.byllm.lib { Model }

glob llm: Model = Model(model_name="gemini/gemini-3.8-flash");

node Zone {
    has name: str = "";
    has x: float = 0.0;
    has y: float = 0.0;
    has demand_morning: float = 0.5;
    has demand_midday: float = 0.5;
    has demand_evening: float = 0.5;
}

node RoadLink {
    has origin: str = "";
    has destination: str = "";
    has distance_km: float = 0.0;
    has traffic_morning: float = 1.0;
    has traffic_midday: float = 1.0;
    has traffic_evening: float = 1.0;
}

node DriverSetup {
    has goals_text: str = "";
    has start_zone: str = "Moratuwa";
    has home_zone: str = "Moratuwa";
    has shift_hours: float = 4.0;
    has target_profit: float = 4500.0;
    has deadline: str = "13:00";
    has preference: str = "profit";
    has vehicle_type: str = "petrol";
    has fuel_efficiency: float = 12.0;
    has fuel_price: float = 350.0;
    has ev_efficiency: float = 7.0;
    has electricity_price: float = 60.0;
}

node SimOffer {
    has pickup: str = "";
    has dropoff: str = "";
    has fare: float = 0.0;
    has distance_km: float = 0.0;
    has duration_min: float = 0.0;
    has pickup_km: float = 0.0;
    has surge: float = 0.0;
    has status: str = "available";
}

node DecisionRecord {
    has offer_id: str = "";
    has decision: str = "";
    has amount: float = 0.0;
    has minutes: float = 0.0;
}

obj GoalDraft {
    has start_zone: str;
    has home_zone: str;
    has shift_hours: float;
    has target_profit: float;
    has deadline: str;
}

obj ZoneView { has name: str, x: float, y: float, demand_morning: float, demand_midday: float, demand_evening: float; }
obj EvaluationView { has trip_net: float, return_value: float, empty_return_cost: float, home_eta: float, deadline_feasible: bool, recommendation: str, reason: str, cost_km: float, trip_cost: float, demand: float, traffic_eta: float; }
obj OfferView { has id: str, pickup: str, dropoff: str, fare: float, distance_km: float, duration_min: float, pickup_km: float, surge: float, status: str, evaluation: EvaluationView; }
obj SetupView { has goals_text: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float; }
obj DecisionView { has offer_id: str, decision: str, amount: float, minutes: float; }
obj WorkspaceView { has setup: SetupView, zones: list[ZoneView], offers: list[OfferView], decisions: list[DecisionView]; }
obj ShiftComparisonView { has naive_profit: float, naive_minutes: float, naive_home_eta: float, naive_location: str, naive_taken: list[str], agent_profit: float, agent_minutes: float, agent_home_eta: float, agent_location: str, agent_taken: list[str], deadline_minutes: float; }

sem GoalDraft.start_zone = "A Sri Lankan zone from the supplied zone list.";
sem GoalDraft.home_zone = "The driver's home zone from the supplied zone list.";
sem GoalDraft.shift_hours = "Requested shift duration in hours.";
sem GoalDraft.target_profit = "Net profit target in simulated Sri Lankan rupees.";
sem GoalDraft.deadline = "Home arrival deadline in 24-hour HH:MM format.";

def parseGoals(text: str) -> GoalDraft by llm(temperature=0.1, max_tokens=300);
sem parseGoals = "Parse a driver's shift request. Defaults when unspecified: start Moratuwa, home Moratuwa, 4 hours, Rs 4500 net, deadline 13:00. Only use these zones: Moratuwa, Colombo Fort, Dehiwala, Nugegoda, Maharagama, Negombo, Galle, Kandy. This is simulated planning data.";
sem parseGoals.text = "Driver's natural-language shift goal.";

def _ensure_workspace() {
    if len([root -->][?:DriverSetup]) == 0 { root ++> DriverSetup(); }
    if len([root -->][?:Zone]) == 0 {
        root ++> Zone(name="Moratuwa", x=16.0, y=66.0, demand_morning=0.72, demand_midday=0.58, demand_evening=0.66);
        root ++> Zone(name="Colombo Fort", x=43.0, y=47.0, demand_morning=0.84, demand_midday=0.78, demand_evening=0.82);
        root ++> Zone(name="Dehiwala", x=33.0, y=62.0, demand_morning=0.70, demand_midday=0.61, demand_evening=0.68);
        root ++> Zone(name="Nugegoda", x=40.0, y=59.0, demand_morning=0.73, demand_midday=0.65, demand_evening=0.71);
        root ++> Zone(name="Maharagama", x=48.0, y=67.0, demand_morning=0.59, demand_midday=0.51, demand_evening=0.60);
        root ++> Zone(name="Negombo", x=39.0, y=20.0, demand_morning=0.63, demand_midday=0.57, demand_evening=0.55);
        root ++> Zone(name="Galle", x=22.0, y=92.0, demand_morning=0.55, demand_midday=0.62, demand_evening=0.58);
        root ++> Zone(name="Kandy", x=78.0, y=45.0, demand_morning=0.66, demand_midday=0.64, demand_evening=0.60);
        root ++> RoadLink(origin="Moratuwa", destination="Colombo Fort", distance_km=20.0, traffic_morning=1.55, traffic_midday=1.12, traffic_evening=1.62);
        root ++> RoadLink(origin="Moratuwa", destination="Dehiwala", distance_km=8.0, traffic_morning=1.38, traffic_midday=1.08, traffic_evening=1.42);
        root ++> RoadLink(origin="Dehiwala", destination="Colombo Fort", distance_km=12.0, traffic_morning=1.48, traffic_midday=1.10, traffic_evening=1.55);
        root ++> RoadLink(origin="Dehiwala", destination="Nugegoda", distance_km=7.0, traffic_morning=1.28, traffic_midday=1.05, traffic_evening=1.34);
        root ++> RoadLink(origin="Nugegoda", destination="Maharagama", distance_km=8.0, traffic_morning=1.25, traffic_midday=1.04, traffic_evening=1.30);
        root ++> RoadLink(origin="Colombo Fort", destination="Negombo", distance_km=38.0, traffic_morning=1.45, traffic_midday=1.12, traffic_evening=1.48);
        root ++> RoadLink(origin="Moratuwa", destination="Galle", distance_km=105.0, traffic_morning=1.18, traffic_midday=1.08, traffic_evening=1.22);
        root ++> RoadLink(origin="Colombo Fort", destination="Kandy", distance_km=118.0, traffic_morning=1.42, traffic_midday=1.15, traffic_evening=1.52);
        root ++> RoadLink(origin="Maharagama", destination="Galle", distance_km=110.0, traffic_morning=1.20, traffic_midday=1.09, traffic_evening=1.24);
        root ++> RoadLink(origin="Colombo Fort", destination="Nugegoda", distance_km=9.0, traffic_morning=1.42, traffic_midday=1.08, traffic_evening=1.48);
        root ++> RoadLink(origin="Negombo", destination="Kandy", distance_km=112.0, traffic_morning=1.34, traffic_midday=1.13, traffic_evening=1.40);
        root ++> RoadLink(origin="Dehiwala", destination="Galle", distance_km=98.0, traffic_morning=1.18, traffic_midday=1.07, traffic_evening=1.20);
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
        root ++> SimOffer(pickup="Moratuwa", dropoff="Dehiwala", fare=1550.0, distance_km=8.0, duration_min=27.0, pickup_km=1.0);
        root ++> SimOffer(pickup="Dehiwala", dropoff="Galle", fare=13900.0, distance_km=98.0, duration_min=138.0, pickup_km=4.0, surge=1200.0);
    }
}

def:pub getDriverWorkspace() -> WorkspaceView {
    _ensure_workspace();
    setups = [root -->][?:DriverSetup];
    setup = setups[0];
    zones = [root -->][?:Zone];
    offers = [root -->][?:SimOffer];
    decisions = [root -->][?:DecisionRecord];
    setup_view = SetupView(goals_text=setup.goals_text, start_zone=setup.start_zone, home_zone=setup.home_zone, shift_hours=setup.shift_hours, target_profit=setup.target_profit, deadline=setup.deadline, preference=setup.preference, vehicle_type=setup.vehicle_type, fuel_efficiency=setup.fuel_efficiency, fuel_price=setup.fuel_price, ev_efficiency=setup.ev_efficiency, electricity_price=setup.electricity_price);
    zone_views: list[ZoneView] = [ZoneView(name=z.name, x=z.x, y=z.y, demand_morning=z.demand_morning, demand_midday=z.demand_midday, demand_evening=z.demand_evening) for z in zones];
    offer_views: list[OfferView] = [];
    for o in offers {
        raw_offer = {"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km, "surge": o.surge};
        metrics = _offer_metrics(raw_offer, setup, zones);
        evaluation = EvaluationView(trip_net=metrics["trip_net"] as float, return_value=metrics["return_value"] as float, empty_return_cost=metrics["empty_return_cost"] as float, home_eta=metrics["home_eta"] as float, deadline_feasible=metrics["deadline_feasible"] as bool, recommendation=metrics["recommendation"] as str, reason=metrics["reason"] as str, cost_km=metrics["cost_km"] as float, trip_cost=metrics["trip_cost"] as float, demand=metrics["demand"] as float, traffic_eta=metrics["traffic_eta"] as float);
        offer_views.append(OfferView(id=jid(o), pickup=o.pickup, dropoff=o.dropoff, fare=o.fare, distance_km=o.distance_km, duration_min=o.duration_min, pickup_km=o.pickup_km, surge=o.surge, status=o.status, evaluation=evaluation));
    }
    decision_views: list[DecisionView] = [DecisionView(offer_id=d.offer_id, decision=d.decision, amount=d.amount, minutes=d.minutes) for d in decisions];
    return WorkspaceView(setup=setup_view, zones=zone_views, offers=offer_views, decisions=decision_views);
}

def:pub saveDriverSetup(goals_text: str, start_zone: str, home_zone: str, shift_hours: float, target_profit: float, deadline: str, preference: str, vehicle_type: str, fuel_efficiency: float, fuel_price: float, ev_efficiency: float, electricity_price: float) -> dict {
    _ensure_workspace();
    if shift_hours <= 0.0 or target_profit < 0.0 or fuel_efficiency <= 0.0 or fuel_price < 0.0 or ev_efficiency <= 0.0 or electricity_price < 0.0 { return {"ok": False, "error": "Enter positive shift and efficiency values and non-negative prices and target."}; }
    setups = [root -->][?:DriverSetup];
    setup = setups[0];
    setup.goals_text = goals_text;
    setup.start_zone = start_zone;
    setup.home_zone = home_zone;
    setup.shift_hours = shift_hours;
    setup.target_profit = target_profit;
    setup.deadline = deadline;
    setup.preference = "route" if preference == "route" else "profit";
    setup.vehicle_type = "ev" if vehicle_type == "ev" else "petrol";
    setup.fuel_efficiency = fuel_efficiency;
    setup.fuel_price = fuel_price;
    setup.ev_efficiency = ev_efficiency;
    setup.electricity_price = electricity_price;
    return {"ok": True};
}

def _vehicle_cost(setup: DriverSetup) -> float {
    if setup.vehicle_type == "ev" { return setup.electricity_price / setup.ev_efficiency; }
    return setup.fuel_price / setup.fuel_efficiency;
}

def _zone_demand(zones: list[Zone], name: str) -> float {
    for z in zones {
        if z.name == name { return (z.demand_morning + z.demand_midday + z.demand_evening) / 3.0; }
    }
    return 0.5;
}

def _minutes_to_deadline(deadline: str, shift_hours: float) -> float {
    bits = deadline.split(":");
    if len(bits) != 2 { return shift_hours * 60.0; }
    try {
        hour = int(bits[0]);
        minute = int(bits[1]);
        remain = hour * 60 + minute - 540;
        return float(remain + 1440 if remain < 0 else remain);
    } except ValueError { return shift_hours * 60.0; }
}

def _offer_metrics(offer: dict, setup: DriverSetup, zones: list[Zone]) -> dict {
    cost_km = _vehicle_cost(setup);
    distance = offer["distance_km"] as float;
    pickup = offer["pickup_km"] as float;
    fare = offer["fare"] as float;
    base_minutes = offer["duration_min"] as float;
    minutes = base_minutes * 1.25;
    trip_cost = (distance + pickup) * cost_km;
    trip_net = fare - trip_cost;
    demand = _zone_demand(zones, offer["dropoff"] as str);
    return_cost = distance * 0.75 * cost_km;
    return_value = demand * fare * 0.55;
    deadline_remaining = _minutes_to_deadline(setup.deadline, setup.shift_hours);
    home_eta = minutes + distance * 0.8 * 2.0;
    feasible = home_eta <= deadline_remaining;
    advice = "ACCEPT";
    reason = "Positive trip net and deadline remains feasible.";
    if not feasible {
        advice = "DECLINE";
        reason = "Taking this trip leaves too little simulated time to return home before the deadline.";
    } elif trip_net + return_value < return_cost {
        advice = "WAIT";
        reason = "Return demand is limited in this simulation; reposition toward a busier zone while waiting.";
    } elif setup.preference == "route" {
        reason = "Consider the shortest traffic-adjusted ETA while comparing the displayed fare and net.";
    } elif trip_net < return_cost * 0.35 {
        advice = "WAIT";
        reason = "Net is modest after energy cost; consider repositioning toward higher simulated demand.";
    }
    return {"trip_net": trip_net, "return_value": return_value, "empty_return_cost": return_cost, "home_eta": home_eta, "deadline_feasible": feasible, "recommendation": advice, "reason": reason, "cost_km": cost_km, "trip_cost": trip_cost, "demand": demand, "traffic_eta": minutes};
}

def:pub getOfferExplanation(offer_text: str, evaluation_text: str) -> str by llm(temperature=0.3, max_tokens=100);
sem getOfferExplanation = "Write a brief plain-language explanation of the provided simulated trip economics and recommendation. Never invent numbers, recommend declining solely because of traffic, or encourage cancelling an accepted ride.";
sem getOfferExplanation.offer_text = "Simulated offer details.";
sem getOfferExplanation.evaluation_text = "Deterministic results and recommendation.";

def:pub evaluateOffer(offer_id: str) -> dict {
    _ensure_workspace();
    offers = [root -->][?:SimOffer];
    setups = [root -->][?:DriverSetup];
    zones = [root -->][?:Zone];
    setup = setups[0];
    for o in offers {
        if jid(o) == offer_id {
            offer = {"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km, "surge": o.surge};
            return _offer_metrics(offer, setup, zones);
        }
    }
    return {"error": "Offer not found."};
}

def:pub decideOffer(offer_id: str, decision: str) -> dict {
    _ensure_workspace();
    if decision != "accept" and decision != "decline" { return {"ok": False, "error": "Choose accept or decline."}; }
    offers = [root -->][?:SimOffer];
    setups = [root -->][?:DriverSetup];
    zones = [root -->][?:Zone];
    setup = setups[0];
    for o in offers {
        if jid(o) == offer_id and o.status == "available" {
            metrics = _offer_metrics({"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km, "surge": o.surge}, setup, zones);
            if decision == "accept" and not (metrics["deadline_feasible"] as bool) { return {"ok": False, "error": "This offer is infeasible against the configured home deadline."}; }
            o.status = "accepted" if decision == "accept" else "declined";
            root ++> DecisionRecord(offer_id=offer_id, decision=decision, amount=(metrics["trip_net"] as float), minutes=(metrics["traffic_eta"] as float));
            return {"ok": True, "offer_id": offer_id, "decision": decision, "metrics": metrics};
        }
    }
    return {"ok": False, "error": "Offer is no longer available."};
}

def:pub getShiftComparison() -> ShiftComparisonView {
    _ensure_workspace();
    setups = [root -->][?:DriverSetup];
    zones = [root -->][?:Zone];
    offers = [root -->][?:SimOffer];
    setup = setups[0];
    records: list[dict] = [];
    for o in offers { records.append({"id": jid(o), "pickup": o.pickup, "dropoff": o.dropoff, "fare": o.fare + o.surge, "distance_km": o.distance_km, "duration_min": o.duration_min, "pickup_km": o.pickup_km}); }
    deadline = _minutes_to_deadline(setup.deadline, setup.shift_hours);
    cost = _vehicle_cost(setup);
    naive_profit = 0.0;
    naive_minutes = 0.0;
    naive_location = setup.start_zone;
    naive_taken: list[str] = [];
    remaining = [r for r in records];
    while len(remaining) > 0 {
        best = remaining[0];
        for r in remaining { if (r["fare"] as float) > (best["fare"] as float) { best = r; } }
        remaining.remove(best);
        base_duration = best["duration_min"] as float;
        distance_for_return = best["distance_km"] as float;
        duration = base_duration * 1.25;
        home_return = distance_for_return * 1.6;
        if naive_minutes + duration + home_return <= deadline {
            naive_minutes += duration;
            naive_profit += (best["fare"] as float) - ((best["distance_km"] as float) + (best["pickup_km"] as float)) * cost;
            naive_location = best["dropoff"] as str;
            naive_taken.append(best["id"] as str);
        }
    }
    agent_profit = 0.0;
    agent_minutes = 0.0;
    agent_location = setup.start_zone;
    agent_taken: list[str] = [];
    for r in records {
        metrics = _offer_metrics(r, setup, zones);
        metric_minutes = metrics["traffic_eta"] as float;
        distance_for_return = r["distance_km"] as float;
        return_mins = distance_for_return * 1.6;
        if (metrics["recommendation"] as str) == "ACCEPT" and agent_minutes + metric_minutes + return_mins <= deadline {
            agent_profit += metrics["trip_net"] as float;
            agent_minutes += metric_minutes;
            agent_location = r["dropoff"] as str;
            agent_taken.append(r["id"] as str);
        }
    }
    return ShiftComparisonView(naive_profit=naive_profit, naive_minutes=naive_minutes, naive_home_eta=naive_minutes + 32.0, naive_location=naive_location, naive_taken=naive_taken, agent_profit=agent_profit, agent_minutes=agent_minutes, agent_home_eta=agent_minutes + 32.0, agent_location=agent_location, agent_taken=agent_taken, deadline_minutes=deadline);
}
