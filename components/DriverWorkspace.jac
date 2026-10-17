sv import from ..services.driverService { GoalDraft, WorkspaceView, ShiftComparisonView, OfferView, ZoneView, EvaluationView, parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, getOfferExplanation, getShiftComparison }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.badge { Badge }
import from .ui.progress { Progress }
import from "@jac/runtime" { jacLogout, useNavigate }
sv import from ..services.accountService { DriverProfileView, getDriverProfile }

def:pub DriverWorkspace() -> JsxElement {
    has state: WorkspaceView | None = None;
    has loading: bool = True;
    has error_message: str = "";
    has message: str = "";
    has deciding: bool = False;
    has selected_index: int = 0;
    has selected_zone: str = "Moratuwa";
    has region: str = "Sri Lanka";
    has goals_text: str = "4 hours, Rs. 4,500 net profit, home in Moratuwa by 1:00 PM";
    has start_zone: str = "Moratuwa";
    has home_zone: str = "Moratuwa";
    has shift_hours: str = "4";
    has target_profit: str = "4500";
    has deadline: str = "13:00";
    has preference: str = "profit";
    has vehicle_type: str = "petrol";
    has fuel_efficiency: str = "12";
    has fuel_price: str = "350";
    has ev_efficiency: str = "7";
    has electricity_price: str = "60";
    has comparison: ShiftComparisonView | None = None;
    has explanation: str = "Select Explain this offer for a Gemini summary. All route information is simulated.";
    has profile: DriverProfileView | None = None;
    nav = useNavigate();

    async can with entry {
        try {
            data = await getDriverWorkspace();
            if data is not None {
                state = data;
                profile = await getDriverProfile();
                region = data.setup.region;
                goals_text = data.setup.goals_text if data.setup.goals_text else goals_text;
                start_zone = data.setup.start_zone;
                home_zone = data.setup.home_zone;
                selected_zone = data.setup.start_zone;
                shift_hours = str(data.setup.shift_hours);
                target_profit = str(data.setup.target_profit);
                deadline = data.setup.deadline;
                preference = data.setup.preference;
                vehicle_type = data.setup.vehicle_type;
                fuel_efficiency = str(data.setup.fuel_efficiency);
                fuel_price = str(data.setup.fuel_price);
                ev_efficiency = str(data.setup.ev_efficiency);
                electricity_price = str(data.setup.electricity_price);
                comparison = await getShiftComparison();
            } else { error_message = "Workspace data is unavailable. Retry loading the map."; }
        } except Exception { error_message = "Workspace data is unavailable. Retry loading the map."; }
        loading = False;
    }

    def handle_goals(e: ChangeEvent) { goals_text = e.target.value; }
    def handle_region(e: ChangeEvent) {
        region = e.target.value;
        if region == "United Kingdom" { start_zone = "London"; home_zone = "London"; selected_zone = "London"; target_profit = "150"; fuel_price = "1.55"; electricity_price = "0.28"; }
        elif region == "United States" { start_zone = "New York"; home_zone = "New York"; selected_zone = "New York"; target_profit = "150"; fuel_price = "3.60"; electricity_price = "0.16"; }
        else { start_zone = "Moratuwa"; home_zone = "Moratuwa"; selected_zone = "Moratuwa"; target_profit = "4500"; fuel_price = "350"; electricity_price = "60"; }
        selected_index = 0;
        message = "Region changed. Save to apply simulated regional settings.";
    }
    def handle_start(e: ChangeEvent) { start_zone = e.target.value; }
    def handle_home(e: ChangeEvent) { home_zone = e.target.value; }
    def handle_hours(e: ChangeEvent) { shift_hours = e.target.value; }
    def handle_target(e: ChangeEvent) { target_profit = e.target.value; }
    def handle_deadline(e: ChangeEvent) { deadline = e.target.value; }
    def handle_fuel_efficiency(e: ChangeEvent) { fuel_efficiency = e.target.value; }
    def handle_fuel_price(e: ChangeEvent) { fuel_price = e.target.value; }
    def handle_ev_efficiency(e: ChangeEvent) { ev_efficiency = e.target.value; }
    def handle_electricity_price(e: ChangeEvent) { electricity_price = e.target.value; }
    def handle_vehicle(e: ChangeEvent) { vehicle_type = e.target.value; }
    def handle_preference(e: ChangeEvent) { preference = e.target.value; }

    async def reload_workspace -> None {
        state = await getDriverWorkspace();
        comparison = await getShiftComparison();
    }

    async def handle_parse -> None {
        if not goals_text.strip() { error_message = "Enter a shift goal to parse."; return; }
        try {
            draft = await parseGoals(goals_text);
            start_zone = draft.start_zone;
            home_zone = draft.home_zone;
            shift_hours = str(draft.shift_hours);
            target_profit = str(draft.target_profit);
            deadline = draft.deadline;
            message = "Parsed goals. Review and save the fields.";
            error_message = "";
        } except Exception { error_message = "Gemini is unavailable. Add GEMINI_API_KEY in Settings, or edit goals manually."; }
    }

    async def handle_save -> None {
        try {
            result = await saveDriverSetup(region, goals_text, start_zone, home_zone, float(shift_hours), float(target_profit), deadline, preference, vehicle_type, float(fuel_efficiency), float(fuel_price), float(ev_efficiency), float(electricity_price));
            if result["ok"] as bool { message = "Driver setup saved."; error_message = ""; await reload_workspace(); }
            else { error_message = result["error"] as str; }
        } except ValueError { error_message = "Enter valid numeric values."; }
    }

    async def handle_decision(choice: str) -> None {
        if state is None or len(state.offers) == 0 { return; }
        offer = state.offers[selected_index];
        result = await decideOffer(offer.id, choice);
        if result["ok"] as bool {
            message = "Offer " + choice + "ed. Simulated tracker updated.";
            error_message = "";
            await reload_workspace();
            if selected_index + 1 < len(state.offers) { selected_index = selected_index + 1; }
            else { selected_index = 0; }
        } else { error_message = result["error"] as str; }
    }

    async def handle_accept -> None {
        message = "Submitting simulated accept decision...";
        deciding = True;
        try {
            if state is None or len(state.offers) == 0 { error_message = "No offer is loaded."; deciding = False; return; }
            result = await decideOffer(state.offers[selected_index].id, "accept");
            if result["ok"] as bool { message = "Offer accepted. Simulated tracker updated."; error_message = ""; await reload_workspace(); }
            else { error_message = result["error"] as str; }
        } except Exception { error_message = "Could not record the simulated decision. Try again."; }
        deciding = False;
    }

    async def handle_decline -> None {
        message = "Submitting simulated decline decision...";
        deciding = True;
        try {
            if state is None or len(state.offers) == 0 { error_message = "No offer is loaded."; deciding = False; return; }
            result = await decideOffer(state.offers[selected_index].id, "decline");
            if result["ok"] as bool { message = "Offer declined."; error_message = ""; await reload_workspace(); }
            else { error_message = result["error"] as str; }
        } except Exception { error_message = "Could not record the simulated decision. Try again."; }
        deciding = False;
    }

    async def handle_next -> None {
        if state is not None and len(state.offers) > 0 { selected_index = (selected_index + 1) % len(state.offers); }
    }

    async def handle_explain -> None {
        if state is not None and len(state.offers) > 0 {
            offer = state.offers[selected_index];
            try { explanation = await getOfferExplanation(str(offer), str(offer.evaluation)); }
            except Exception { explanation = "Gemini explanation unavailable; deterministic calculations remain visible."; }
        }
    }

    async def handle_refresh_comparison -> None { comparison = await getShiftComparison(); }
    def select_zone(name: str) { selected_zone = name; }

    if loading { return <div className="min-h-svh bg-muted/40 p-6"><div className="mx-auto w-full max-w-7xl animate-pulse rounded-2xl border bg-card p-8"><div className="h-8 w-56 rounded bg-muted"/><div className="mt-6 h-64 rounded-xl bg-muted"/></div></div>; }

    zones_data: list[ZoneView] = state.zones if state is not None else [];
    offers_data: list[OfferView] = state.offers if state is not None else [];
    current_offer: OfferView | None = offers_data[selected_index] if len(offers_data) > 0 else None;
    current_eval: EvaluationView | None = current_offer.evaluation if current_offer is not None else None;
    route_origin = current_offer.pickup if current_offer is not None else start_zone;
    route_dest = current_offer.dropoff if current_offer is not None else selected_zone;
    tracked_zone = state.tracked_zone if state is not None else start_zone;
    currency = state.setup.currency if state is not None else "LKR";
    unit = state.setup.distance_unit if state is not None else "km";
    time_zone = state.setup.time_zone if state is not None else "Asia/Colombo";
    cost_km = current_eval.cost_km if current_eval is not None else (float(fuel_price) / float(fuel_efficiency) if vehicle_type == "petrol" else float(electricity_price) / float(ev_efficiency));
    running_net = 0.0;
    time_used = 0.0;
    if state is not None { for d in state.decisions { if d.decision == "accept" { running_net += d.amount; time_used += d.minutes; } } }
    goal_value = float(target_profit);
    progress_value = 0.0 if goal_value <= 0.0 else min(100.0, running_net / goal_value * 100.0);
    fastest_eta = current_offer.duration_min * 1.25 if current_offer is not None else 0.0;
    least_eta = current_offer.duration_min * 1.08 if current_offer is not None else 0.0;
    selected_region = "Island-wide";
    for z in zones_data { if z.name == selected_zone { selected_region = z.region; } }
    priority_label = "profit priority";
    if preference == "route" { priority_label = "shortest ETA"; }
    km_multiplier = 1.0;
    if unit == "miles" { km_multiplier = 0.621371; }
    selected_demand = 0.5;
    route_x1 = 40.0;
    route_y1 = 70.0;
    route_x2 = 60.0;
    route_y2 = 40.0;
    tracked_x = 40.0;
    tracked_y = 70.0;
    for z in zones_data {
        if z.name == selected_zone { selected_demand = (z.demand_morning + z.demand_midday + z.demand_evening) / 3.0; }
        if z.name == route_origin { route_x1 = z.x; route_y1 = z.y; }
        if z.name == route_dest { route_x2 = z.x; route_y2 = z.y; }
        if z.name == tracked_zone { tracked_x = z.x; tracked_y = z.y; }
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-card"><div className="mx-auto flex w-full max-w-[1600px] flex-wrap items-center justify-between gap-3 px-4 py-4 md:px-7"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground font-bold">H</div><div><p className="text-lg font-semibold tracking-tight">HireWise</p><p className="text-xs text-muted-foreground">Driver decision workspace · {region}</p></div></div><div className="flex flex-wrap items-center gap-2"><span className="text-xs text-muted-foreground">Signed-in driver</span><select aria-label="Select region" value={region} onChange={handle_region} className="h-9 rounded-lg border border-input bg-background px-2 text-sm"><option value="Sri Lanka">Sri Lanka</option><option value="United Kingdom">United Kingdom</option><option value="United States">United States</option></select><Badge variant="outline" className="border-amber-500/40 bg-amber-500/10 text-amber-800">Simulated data</Badge><button type="button" onClick={lambda { jacLogout(); nav("/account"); }} className="rounded-lg border px-3 py-2 text-sm">Sign out</button></div></div></header>
        <main className="mx-auto flex w-full max-w-[1600px] flex-col gap-5 px-4 py-5 md:px-7 md:py-7">
            <div className="flex flex-wrap items-end justify-between gap-4"><div><h1 className="text-2xl font-semibold tracking-tight">Plan your {region} shift</h1><p className="mt-1 text-sm text-muted-foreground">Simulated offers and position · times shown for {time_zone}.</p></div><p className="text-xs text-muted-foreground">Illustrative routes, demand, fares and travel times</p></div>
            {error_message and <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">{error_message}</p>}{message and <p role="status" className="rounded-lg border border-primary/20 bg-primary/5 px-4 py-3 text-sm">{message}</p>}
            <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.2fr)_minmax(0,0.95fr)]">
                <div className="flex min-w-0 flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Shift goals</CardTitle><CardDescription>Describe your shift, then confirm the parsed fields.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Goal in your words<Textarea value={goals_text} onChange={handle_goals} placeholder="4 hours, Rs. 4,500 net, home by 1:00 PM"/></label><Button variant="outline" onClick={handle_parse}>Parse with Gemini</Button>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Starting zone<select value={start_zone} onChange={handle_start} className="h-9 rounded-lg border border-input bg-background px-3 text-sm">{for z in zones_data { <option key={z.name} value={z.name}>{z.name} · {z.region}</option> }}</select></label>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Home zone<select value={home_zone} onChange={handle_home} className="h-9 rounded-lg border border-input bg-background px-3 text-sm">{for z in zones_data { <option key={z.name} value={z.name}>{z.name} · {z.region}</option> }}</select></label>
                        <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Shift hours<Input type="number" min="0.5" step="0.5" value={shift_hours} onChange={handle_hours}/></label><label className="flex flex-col gap-1.5 text-sm font-medium">Net target ({currency})<Input type="number" min="0" value={target_profit} onChange={handle_target}/></label></div>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Home by<Input type="time" value={deadline} onChange={handle_deadline}/></label>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Your priority<select value={preference} onChange={handle_preference} className="h-9 rounded-lg border border-input bg-background px-3 text-sm"><option value="profit">Prioritize profit</option><option value="route">Prioritize shortest ETA</option></select></label>
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Vehicle energy cost</CardTitle><CardDescription>Simulated costs; calculations are deterministic.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Vehicle type<select value={vehicle_type} onChange={handle_vehicle} className="h-9 rounded-lg border border-input bg-background px-3 text-sm"><option value="petrol">Petrol</option><option value="ev">Electric vehicle</option></select></label>
                        {vehicle_type == "petrol" and <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Efficiency ({unit}/L)<Input type="number" min="0.1" value={fuel_efficiency} onChange={handle_fuel_efficiency}/></label><label className="flex flex-col gap-1.5 text-sm font-medium">Fuel ({currency}/L)<Input type="number" min="0" value={fuel_price} onChange={handle_fuel_price}/></label></div>}
                        {vehicle_type == "ev" and <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Efficiency ({unit}/kWh)<Input type="number" min="0.1" value={ev_efficiency} onChange={handle_ev_efficiency}/></label><label className="flex flex-col gap-1.5 text-sm font-medium">Electricity ({currency}/kWh)<Input type="number" min="0" value={electricity_price} onChange={handle_electricity_price}/></label></div>}
                        <div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Energy cost per {unit}</p><p className="text-xl font-semibold tabular-nums">{currency} {round(cost_km, 2)}</p></div><Button onClick={handle_save}>Save driver setup</Button>
                    </CardContent></Card>
                </div>
                <div className="flex min-w-0 flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-2"><div><CardTitle>Simulated {region} zone map</CardTitle><CardDescription>Choose a zone to inspect simulated demand. Position is illustrative, not GPS.</CardDescription></div><Badge variant="secondary">{selected_region}</Badge></div></CardHeader><CardContent>
                        <svg viewBox="0 0 100 104" className="h-[380px] w-full rounded-xl border bg-background p-2" role="img" aria-label="Simulated region zone diagram">
                            <rect x="5" y="5" width="90" height="92" rx="8" fill="currentColor" fillOpacity=".025" stroke="currentColor" strokeOpacity=".18" strokeWidth=".7"/><text x="8" y="12" fontSize="3" fill="currentColor">{region} · simulated zone layout</text>
                            <line x1={str(route_x1)} y1={str(route_y1)} x2={str(route_x2)} y2={str(route_y2)} stroke="#0f766e" strokeWidth="1.2" strokeDasharray="2 1"/>
                            <circle cx={str(tracked_x)} cy={str(tracked_y)} r="2.3" fill="#f97316"/>
                            {for z in zones_data { <g key={z.name}><circle cx={str(z.x)} cy={str(z.y)} r="1.2" fill="#64748b"/><text x={str(z.x + 1.3)} y={str(z.y + 1.0)} fontSize="2.5" fill="currentColor">{z.name}</text></g> }}
                        </svg>
                        <div className="mt-3 grid grid-cols-2 gap-2 text-xs sm:grid-cols-3"><div className="rounded-lg bg-muted/60 p-2"><p className="text-muted-foreground">Selected district</p><p className="font-medium">{selected_zone}</p></div><div className="rounded-lg bg-muted/60 p-2"><p className="text-muted-foreground">Simulated demand</p><p className="font-medium">{round(selected_demand * 100.0, 0)}%</p></div><div className="rounded-lg bg-muted/60 p-2"><p className="text-muted-foreground">Driver tracker</p><p className="font-medium">{tracked_zone}</p></div></div>
                        <div className="mt-3 flex flex-wrap gap-2">{for z in zones_data { <Button key={z.name} variant={"default" if z.name == selected_zone else "outline"} size="sm" onClick={lambda { select_zone(z.name); }}>{z.name}</Button> }}</div>
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Shift tracker</CardTitle><CardDescription>Simulated accepted rides move the marker to each destination.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4"><div className="grid grid-cols-3 gap-2"><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Net profit</p><p className="font-semibold tabular-nums">{currency} {round(running_net, 0)}</p></div><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Time used</p><p className="font-semibold tabular-nums">{round(time_used, 0)} min</p></div><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Target</p><p className="font-semibold tabular-nums">{currency} {round(goal_value, 0)}</p></div></div><div><div className="mb-2 flex justify-between text-sm"><span>Progress to net target</span><span>{round(progress_value, 0)}%</span></div><Progress value={progress_value}/></div></CardContent></Card>
                </div>
                <div className="flex min-w-0 flex-col gap-5">
                    <Card className="border-primary/25 shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-2"><div><CardTitle>Current simulated offer</CardTitle><CardDescription>Review route economics; you make the final decision.</CardDescription></div>{current_eval and <Badge>{current_eval.recommendation}</Badge>}</div></CardHeader><CardContent className="flex flex-col gap-4">
                        {current_offer and <div className="rounded-xl bg-primary/5 p-4"><p className="text-xs font-medium text-primary">OFFER {selected_index + 1} OF {len(offers_data)}</p><p className="mt-2 text-lg font-semibold">{current_offer.pickup} to {current_offer.dropoff}</p><p className="mt-1 text-sm text-muted-foreground">{current_offer.distance_km} simulated km · {current_offer.duration_min} base minutes · surge Rs. {current_offer.surge}</p><p className="mt-3 text-2xl font-semibold">Rs. {round(current_offer.fare + current_offer.surge, 0)}</p></div>}
                        {current_eval and <div className="grid grid-cols-2 gap-2"><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Trip net after energy</p><p className="font-semibold">Rs. {round(current_eval.trip_net, 0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Empty return cost</p><p className="font-semibold">Rs. {round(current_eval.empty_return_cost, 0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Return ride potential</p><p className="font-semibold">Rs. {round(current_eval.return_value, 0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Home ETA</p><p className="font-semibold">{round(current_eval.home_eta, 0)} min</p></div></div>}
                        {current_eval and <p className="rounded-lg border bg-background p-3 text-sm">{current_eval.reason}</p>}
                        <div className="rounded-lg bg-muted/50 p-3"><p className="text-xs font-medium text-muted-foreground">Gemini explanation</p><p className="mt-1 text-sm">{explanation}</p><Button variant="outline" size="sm" className="mt-2" onClick={handle_explain}>Explain offer</Button></div>
                        <div className="flex flex-wrap gap-2"><button type="button" disabled={current_offer is None or deciding} onClick={handle_accept} className="inline-flex h-9 items-center justify-center rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground disabled:pointer-events-none disabled:opacity-50">Accept offer</button><button type="button" disabled={current_offer is None or deciding} onClick={handle_decline} className="inline-flex h-9 items-center justify-center rounded-lg border border-border bg-background px-4 text-sm font-medium hover:bg-muted disabled:pointer-events-none disabled:opacity-50">Decline offer</button><Button variant="secondary" disabled={current_offer is None} onClick={handle_next}>Next offer</Button></div>
                        {current_offer and <div className="border-t pt-3"><p className="mb-2 text-xs font-medium text-muted-foreground">Route alternatives · simulated</p><div className="flex justify-between text-sm"><span>Shortest traffic-adjusted ETA</span><span>{round(fastest_eta, 0)} min</span></div><div className="flex justify-between text-sm"><span>Offer fare</span><span>Rs. {round(current_offer.fare, 0)}</span></div><div className="flex justify-between text-sm"><span>Lower-traffic estimate</span><span>{round(least_eta, 0)} min</span></div></div>}
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Full-shift comparison</CardTitle><CardDescription>Same simulated offers; naive means highest fare first.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><div className="grid grid-cols-2 gap-3"><div className="rounded-lg border p-3"><p className="text-sm font-medium">Naive · highest fare</p><p className="mt-2 text-lg font-semibold">Rs. {round(comparison.naive_profit if comparison is not None else 0.0, 0)}</p><p className="text-xs text-muted-foreground">Home ETA {round(comparison.naive_home_eta if comparison is not None else 0.0, 0)} min</p></div><div className="rounded-lg border border-primary/30 bg-primary/5 p-3"><p className="text-sm font-medium">HireWise · {"shortest ETA" if preference == "route" else "profit priority"}</p><p className="mt-2 text-lg font-semibold">Rs. {round(comparison.agent_profit if comparison is not None else 0.0, 0)}</p><p className="text-xs text-muted-foreground">Home ETA {round(comparison.agent_home_eta if comparison is not None else 0.0, 0)} min</p></div></div><p className="text-xs text-muted-foreground">Naive skips only if projected return home misses the deadline. All values are simulated.</p><Button variant="outline" onClick={handle_refresh_comparison}>Recalculate simulation</Button></CardContent></Card>
                </div>
            </div>
        </main>
    </div>;
}
