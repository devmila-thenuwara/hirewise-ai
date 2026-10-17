sv import from ..services.driverService { GoalDraft, WorkspaceView, ShiftComparisonView, OfferView, ZoneView, EvaluationView, parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, getOfferExplanation, getShiftComparison }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.badge { Badge }
import from .ui.progress { Progress }

def:pub DriverWorkspace() -> JsxElement {
    has state: WorkspaceView | None = None;
    has loading: bool = True;
    has error_message: str = "";
    has message: str = "";
    has selected_index: int = 0;
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
    has explanation: str = "Select Explain this offer for a Gemini summary. Calculations remain deterministic.";

    async can with entry {
        try {
            state = await getDriverWorkspace();
            if state is not None {
                goals_text = state.setup.goals_text if state.setup.goals_text else goals_text;
                start_zone = state.setup.start_zone;
                home_zone = state.setup.home_zone;
                shift_hours = str(state.setup.shift_hours);
                target_profit = str(state.setup.target_profit);
                deadline = state.setup.deadline;
                preference = state.setup.preference;
                vehicle_type = state.setup.vehicle_type;
                fuel_efficiency = str(state.setup.fuel_efficiency);
                fuel_price = str(state.setup.fuel_price);
                ev_efficiency = str(state.setup.ev_efficiency);
                electricity_price = str(state.setup.electricity_price);
                comparison = await getShiftComparison();
            } else { error_message = "Workspace data could not be loaded. Refresh to retry."; }
        } except Exception { error_message = "Workspace data could not be loaded. Refresh to retry."; }
        loading = False;
    }

    def handle_goals(e: ChangeEvent) { goals_text = e.target.value; }
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
            message = "Goal parsed. Review the fields and save your setup.";
            error_message = "";
        } except Exception { error_message = "Goal parsing failed. Check GEMINI_API_KEY in JacHammer Settings; you can still edit goals manually."; }
    }

    async def handle_save -> None {
        try {
            result = await saveDriverSetup(goals_text, start_zone, home_zone, float(shift_hours), float(target_profit), deadline, preference, vehicle_type, float(fuel_efficiency), float(fuel_price), float(ev_efficiency), float(electricity_price));
            if result["ok"] as bool { message = "Driver setup saved."; error_message = ""; await reload_workspace(); }
            else { error_message = result["error"] as str; }
        } except ValueError { error_message = "Enter valid numeric values in the shift and vehicle fields."; }
    }

    async def handle_decision(choice: str) -> None {
        if state is None or len(state.offers) == 0 { return; }
        offer = state.offers[selected_index];
        result = await decideOffer(offer.id, choice);
        if result["ok"] as bool {
            message = "Offer " + choice + "ed. Tracker and comparison refreshed.";
            error_message = "";
            await reload_workspace();
            if state is not None and selected_index + 1 < len(state.offers) { selected_index = selected_index + 1; }
            else { selected_index = 0; }
        } else { error_message = result["error"] as str; }
    }

    async def handle_next -> None {
        if state is not None and len(state.offers) > 0 { selected_index = (selected_index + 1) % len(state.offers); }
    }

    async def handle_explain -> None {
        if state is not None and len(state.offers) > 0 {
            offer = state.offers[selected_index];
            try { explanation = await getOfferExplanation(str(offer), str(offer.evaluation)); }
            except Exception { explanation = "Gemini explanation unavailable. Deterministic calculations still guide the recommendation."; }
        }
    }

    async def handle_refresh_comparison -> None { comparison = await getShiftComparison(); }

    if loading { return <div className="min-h-svh bg-muted/40 p-6"><div className="mx-auto w-full max-w-7xl animate-pulse rounded-2xl border bg-card p-8"><div className="h-8 w-56 rounded bg-muted" /><div className="mt-6 h-64 rounded-xl bg-muted" /></div></div>; }

    offers_data: list[OfferView] = state.offers if state is not None else [];
    zones_data: list[ZoneView] = state.zones if state is not None else [];
    current_offer: OfferView | None = offers_data[selected_index] if len(offers_data) > 0 else None;
    current_eval: EvaluationView | None = current_offer.evaluation if current_offer is not None else None;
    cost_km = current_eval.cost_km if current_eval is not None else ((float(fuel_price) / float(fuel_efficiency)) if vehicle_type == "petrol" else (float(electricity_price) / float(ev_efficiency)));
    running_net = 0.0;
    time_used = 0.0;
    if state is not None { for record in state.decisions { if record.decision == "accept" { running_net += record.amount; time_used += record.minutes; } } }
    goal_value = float(target_profit);
    progress_value = 0.0 if goal_value <= 0.0 else min(100.0, running_net / goal_value * 100.0);
    fastest_eta = current_offer.duration_min * 1.25 if current_offer is not None else 0.0;
    least_traffic_eta = current_offer.duration_min * 1.08 if current_offer is not None else 0.0;

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-card"><div className="mx-auto flex w-full max-w-[1600px] flex-wrap items-center justify-between gap-3 px-4 py-4 md:px-7"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground font-bold">H</div><div><p className="text-lg font-semibold tracking-tight">HireWise</p><p className="text-xs text-muted-foreground">Driver decision workspace · Sri Lanka</p></div></div><Badge variant="outline" className="border-amber-500/40 bg-amber-500/10 text-amber-800">Simulated data</Badge></div></header>
        <main className="mx-auto flex w-full max-w-[1600px] flex-col gap-5 px-4 py-5 md:px-7 md:py-7">
            <div className="flex flex-wrap items-end justify-between gap-4"><div><h1 className="text-2xl font-semibold tracking-tight">Your shift, with a clearer call</h1><p className="mt-1 text-sm text-muted-foreground">Estimate trip costs, return potential and time at home before you decide.</p></div><p className="text-xs text-muted-foreground">Illustrative zone, fare, traffic and energy assumptions</p></div>
            {error_message and <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">{error_message}</p>}{message and <p role="status" className="rounded-lg border border-primary/20 bg-primary/5 px-4 py-3 text-sm">{message}</p>}
            <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.2fr)_minmax(0,0.95fr)]">
                <div className="flex flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Shift goals</CardTitle><CardDescription>Describe the shift, then confirm or edit the parsed fields.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Goal in your words<Textarea value={goals_text} onChange={handle_goals} placeholder="4 hours, Rs. 4,500 net, home by 1:00 PM" /></label><Button variant="outline" onClick={handle_parse}>Parse with Gemini</Button>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Starting zone<select value={start_zone} onChange={handle_start} className="h-9 rounded-lg border border-input bg-background px-3 text-sm">{for z in zones_data { <option key={z.name} value={z.name}>{z.name}</option> }}</select></label>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Home zone<select value={home_zone} onChange={handle_home} className="h-9 rounded-lg border border-input bg-background px-3 text-sm">{for z in zones_data { <option key={z.name} value={z.name}>{z.name}</option> }}</select></label>
                        <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Shift hours<Input type="number" min="0.5" step="0.5" value={shift_hours} onChange={handle_hours} /></label><label className="flex flex-col gap-1.5 text-sm font-medium">Net target (Rs)<Input type="number" min="0" value={target_profit} onChange={handle_target} /></label></div>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Home by<Input type="time" value={deadline} onChange={handle_deadline} /></label>
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Your priority<select value={preference} onChange={handle_preference} className="h-9 rounded-lg border border-input bg-background px-3 text-sm"><option value="profit">Prioritize profit</option><option value="route">Prioritize shortest ETA</option></select></label>
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Vehicle energy cost</CardTitle><CardDescription>Illustrative prices; calculations are deterministic.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">
                        <label className="flex flex-col gap-1.5 text-sm font-medium">Vehicle type<select value={vehicle_type} onChange={handle_vehicle} className="h-9 rounded-lg border border-input bg-background px-3 text-sm"><option value="petrol">Petrol</option><option value="ev">Electric vehicle</option></select></label>
                        {vehicle_type == "petrol" and <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Efficiency (km/L)<Input type="number" min="0.1" step="0.1" value={fuel_efficiency} onChange={handle_fuel_efficiency} /></label><label className="flex flex-col gap-1.5 text-sm font-medium">Fuel (Rs/L)<Input type="number" min="0" value={fuel_price} onChange={handle_fuel_price} /></label></div>}
                        {vehicle_type == "ev" and <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1.5 text-sm font-medium">Efficiency (km/kWh)<Input type="number" min="0.1" step="0.1" value={ev_efficiency} onChange={handle_ev_efficiency} /></label><label className="flex flex-col gap-1.5 text-sm font-medium">Electricity (Rs/kWh)<Input type="number" min="0" value={electricity_price} onChange={handle_electricity_price} /></label></div>}
                        <div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Vehicle energy cost</p><p className="text-xl font-semibold tabular-nums">Rs. {str(cost_km)} <span className="text-sm font-normal text-muted-foreground">per km</span></p></div><Button onClick={handle_save}>Save driver setup</Button>
                    </CardContent></Card>
                </div>
                <div className="flex flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Sri Lanka zone graph</CardTitle><CardDescription>Diagram positions and demand scores are simulated, not a live map.</CardDescription></CardHeader><CardContent>
                        <svg viewBox="0 0 100 112" className="h-72 w-full rounded-xl border bg-background p-3" role="img" aria-label="Simulated Sri Lankan zones and road links"><line x1="16" y1="66" x2="43" y2="47" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="16" y1="66" x2="33" y2="62" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="33" y1="62" x2="43" y2="47" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="33" y1="62" x2="40" y2="59" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="40" y1="59" x2="48" y2="67" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="43" y1="47" x2="39" y2="20" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="16" y1="66" x2="22" y2="92" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="43" y1="47" x2="78" y2="45" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="48" y1="67" x2="22" y2="92" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="43" y1="47" x2="40" y2="59" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="39" y1="20" x2="78" y2="45" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/><line x1="33" y1="62" x2="22" y2="92" stroke="currentColor" strokeOpacity=".3" strokeWidth="1.2"/>{for z in zones_data { <g key={z.name}><circle cx={str(z.x)} cy={str(z.y)} r="2.2" fill="#0f766e"/><text x={str(z.x + 2.5)} y={str(z.y + 1.5)} fontSize="3.3" fill="currentColor">{z.name}</text></g> }}</svg>
                        <div className="mt-3 flex flex-wrap gap-2">{for z in zones_data { <span key={z.name} className="rounded-md bg-muted/70 px-2 py-1 text-xs">{z.name} · simulated demand</span> }}</div>
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Shift tracker</CardTitle><CardDescription>Updates from accepted simulated offers.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4"><div className="grid grid-cols-3 gap-3"><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Net profit</p><p className="mt-1 text-lg font-semibold tabular-nums">Rs. {running_net.toFixed(0)}</p></div><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Time used</p><p className="mt-1 text-lg font-semibold tabular-nums">{time_used.toFixed(0)} min</p></div><div className="rounded-lg bg-muted/60 p-3"><p className="text-xs text-muted-foreground">Target</p><p className="mt-1 text-lg font-semibold tabular-nums">Rs. {goal_value.toFixed(0)}</p></div></div><div><div className="mb-2 flex justify-between text-sm"><span>Progress to net target</span><span className="tabular-nums">{progress_value.toFixed(0)}%</span></div><Progress value={progress_value} /></div></CardContent></Card>
                </div>
                <div className="flex flex-col gap-5">
                    <Card className="border-primary/25 shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-2"><div><CardTitle>Current simulated offer</CardTitle><CardDescription>Review the economics; you make the final call.</CardDescription></div>{current_eval and <Badge>{current_eval.recommendation}</Badge>}</div></CardHeader><CardContent className="flex flex-col gap-4">
                        {current_offer and <div className="rounded-xl bg-primary/5 p-4"><p className="text-xs font-medium text-primary">OFFER {selected_index + 1} OF {len(offers_data)}</p><p className="mt-2 text-lg font-semibold">{current_offer.pickup} <span className="text-muted-foreground">to</span> {current_offer.dropoff}</p><p className="mt-1 text-sm text-muted-foreground">{current_offer.distance_km} km · {current_offer.duration_min} min base · {current_offer.surge} Rs surge bonus</p><p className="mt-3 text-2xl font-semibold tabular-nums">Rs. {(current_offer.fare + current_offer.surge).toFixed(0)}</p></div>}
                        {not current_offer and <div className="rounded-xl border border-dashed p-6 text-center"><p className="font-medium">No simulated offers</p><p className="mt-1 text-sm text-muted-foreground">Offers will appear here when available.</p></div>}
                        {current_eval and <div className="grid grid-cols-2 gap-2"><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Trip net after energy</p><p className="font-semibold tabular-nums">Rs. {current_eval.trip_net.toFixed(0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Empty return cost</p><p className="font-semibold tabular-nums">Rs. {current_eval.empty_return_cost.toFixed(0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Return ride potential</p><p className="font-semibold tabular-nums">Rs. {current_eval.return_value.toFixed(0)}</p></div><div className="rounded-lg border p-3"><p className="text-xs text-muted-foreground">Estimated home ETA</p><p className="font-semibold tabular-nums">{current_eval.home_eta.toFixed(0)} min</p></div></div>}
                        {current_eval and <p className="rounded-lg border bg-background p-3 text-sm leading-relaxed">{current_eval.reason}</p>}
                        <div className="rounded-lg bg-muted/50 p-3"><p className="text-xs font-medium text-muted-foreground">Gemini explanation</p><p className="mt-1 text-sm leading-relaxed">{explanation}</p><Button variant="outline" size="sm" className="mt-2" onClick={handle_explain}>Explain this offer</Button></div>
                        <p className="text-xs text-muted-foreground">Fastest means shortest traffic-adjusted ETA. Fare and net stay visible; alternatives are simulated.</p>
                        <div className="flex flex-wrap gap-2"><Button disabled={current_offer is None} onClick={lambda { handle_decision("accept"); }}>Accept offer</Button><Button variant="outline" disabled={current_offer is None} onClick={lambda { handle_decision("decline"); }}>Decline offer</Button><Button variant="secondary" disabled={current_offer is None} onClick={handle_next}>Next offer</Button></div>
                        {current_offer and <div className="border-t pt-3"><p className="mb-2 text-xs font-medium text-muted-foreground">Route alternatives · simulated</p><div className="flex flex-col gap-2 text-sm"><div className="flex justify-between gap-2"><span>Shortest ETA</span><span className="tabular-nums">{str(fastest_eta)} min · Rs. {(current_offer.fare + current_offer.surge).toFixed(0)}</span></div><div className="flex justify-between gap-2"><span>Cheapest offer</span><span className="tabular-nums">Rs. {current_offer.fare.toFixed(0)}</span></div><div className="flex justify-between gap-2"><span>Least traffic</span><span className="tabular-nums">{str(least_traffic_eta)} min baseline</span></div></div></div>}
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Full-shift simulation</CardTitle><CardDescription>Same simulated offers and deadline, two decision rules.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4"><div className="grid grid-cols-2 gap-3"><div className="rounded-lg border p-3"><p className="text-sm font-medium">Naive · highest fare</p><p className="mt-2 text-xl font-semibold tabular-nums">Rs. {(comparison["naive_profit"] as float).toFixed(0)}</p><p className="mt-1 text-xs text-muted-foreground">Home ETA: {(comparison["naive_home_eta"] as float).toFixed(0)} min</p></div><div className="rounded-lg border border-primary/30 bg-primary/5 p-3"><p className="text-sm font-medium">HireWise · {preference == "route" and "shortest ETA" or "profit priority"}</p><p className="mt-2 text-xl font-semibold tabular-nums">Rs. {(comparison["agent_profit"] as float).toFixed(0)}</p><p className="mt-1 text-xs text-muted-foreground">Home ETA: {(comparison["agent_home_eta"] as float).toFixed(0)} min</p></div></div><p className="text-xs leading-relaxed text-muted-foreground">Naive takes the highest-fare offer first and skips only when simulated return home misses your deadline. HireWise considers energy cost, demand, and your preference. All values are illustrative.</p><Button variant="outline" onClick={handle_refresh_comparison}>Recalculate full shift</Button></CardContent></Card>
                </div>
            </div>
        </main>
    </div>;
}
