sv import from ..services.driverService { WorkspaceView, OfferView, parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, getShiftComparison, ShiftComparisonView, evaluateOfferScenario, ScenarioView, getPassengerRequests, PassengerRideRequest }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from .TomTomMap { TomTomMap }
import from "@jac/runtime" { jacLogout, useNavigate }

def:pub DriverWorkspace() -> JsxElement {
    has workspace: WorkspaceView | None = None;
    has loading: bool = True;
    has busy: bool = False;
    has notice: str = "";
    has error_message: str = "";
    has goals_text: str = "";
    has region: str = "Sri Lanka";
    has start_zone: str = "Moratuwa";
    has home_zone: str = "Moratuwa";
    has shift_hours: str = "4";
    has target_profit: str = "4500";
    has deadline: str = "13:00";
    has preference: str = "profit";
    has vehicle_type: str = "petrol";
    has fuel_efficiency: str = "12";
    has fuel_price: str = "350";
    has map_message: str = "";
    has compare: ShiftComparisonView | None = None;
    has weather: str = "clear";
    has time_band: str = "midday";
    has scenario: ScenarioView | None = None;
    has passenger_requests: list[PassengerRideRequest] = [];
    has account_role: str = "driver";
    has map_ref: Ref[HTMLDivElement] = Ref();
    nav = useNavigate();

    async can with entry {
        try {
            account_role = "driver";
            workspace = await getDriverWorkspace();
            passenger_requests = await getPassengerRequests();
            goals_text = workspace.setup.goals_text;
            region = workspace.setup.region;
            start_zone = workspace.setup.start_zone;
            home_zone = workspace.setup.home_zone;
            shift_hours = str(workspace.setup.shift_hours);
            target_profit = str(workspace.setup.target_profit);
            deadline = workspace.setup.deadline;
            preference = workspace.setup.preference;
            vehicle_type = workspace.setup.vehicle_type;
            fuel_efficiency = str(workspace.setup.fuel_efficiency);
            fuel_price = str(workspace.setup.fuel_price);
            loading = False;
        } except Exception { error_message = "Could not load your simulated workspace. Refresh to try again."; loading = False; }
    }

    def on_goals(e: ChangeEvent) { goals_text = e.target.value; }
    def on_region(e: ChangeEvent) { region = e.target.value; }
    def on_start(e: ChangeEvent) { start_zone = e.target.value; }
    def on_home(e: ChangeEvent) { home_zone = e.target.value; }
    def on_hours(e: ChangeEvent) { shift_hours = e.target.value; }
    def on_target(e: ChangeEvent) { target_profit = e.target.value; }
    def on_deadline(e: ChangeEvent) { deadline = e.target.value; }
    def on_preference(e: ChangeEvent) { preference = e.target.value; }
    def on_vehicle(e: ChangeEvent) { vehicle_type = e.target.value; }
    def on_efficiency(e: ChangeEvent) { fuel_efficiency = e.target.value; }
    def on_fuel_price(e: ChangeEvent) { fuel_price = e.target.value; }
    def on_weather(e: ChangeEvent) { weather = e.target.value; scenario = None; }
    def on_time_band(e: ChangeEvent) { time_band = e.target.value; scenario = None; }
    def show_map_message(message: str) { map_message = message; }

    async def refresh_workspace -> None {
        workspace = await getDriverWorkspace();
        loading = False;
    }

    async def save_setup -> None {
        busy = True;
        error_message = "";
        try {
            result = await saveDriverSetup(region, goals_text, start_zone, home_zone, float(shift_hours), float(target_profit), deadline, preference, vehicle_type, float(fuel_efficiency), float(fuel_price), 7.0, 60.0);
            if result["ok"] as bool { await refresh_workspace(); notice = "Shift setup saved."; }
            else { error_message = str(result["error"]); }
        } except Exception { error_message = "Check your shift and vehicle values, then try again."; }
        busy = False;
    }

    async def parse_goals -> None {
        busy = True;
        error_message = "";
        try {
            draft = await parseGoals(goals_text);
            start_zone = draft.start_zone;
            home_zone = draft.home_zone;
            shift_hours = str(draft.shift_hours);
            target_profit = str(draft.target_profit);
            deadline = draft.deadline;
            notice = "Review the parsed goals, then save your shift setup.";
        } except Exception { error_message = "Goal parsing is unavailable. You can enter the shift details directly."; }
        busy = False;
    }

    async def decide(offer_id: str, action: str) -> None {
        busy = True;
        error_message = "";
        try {
            result = await decideOffer(offer_id, action);
            if result["ok"] as bool { await refresh_workspace(); notice = "Offer decision saved."; }
            else { error_message = str(result["error"]); }
        } except Exception { error_message = "Could not save that offer decision."; }
        busy = False;
    }

    async def compare_shift -> None {
        busy = True;
        try { compare = await getShiftComparison(); }
        except Exception { error_message = "Full-shift comparison is unavailable right now."; }
        busy = False;
    }

    async def evaluate_scenario(offer_id: str) -> None {
        busy = True; error_message = "";
        try { scenario = await evaluateOfferScenario(offer_id, weather, time_band); }
        except Exception { error_message = "Scenario evaluation is unavailable for this offer."; }
        busy = False;
    }

    async def refresh_requests -> None {
        try { passenger_requests = await getPassengerRequests(); }
        except Exception { passenger_requests = []; }
    }

    async def sign_out -> None {
        await jacLogout();
        nav("/account");
    }

    active_offers: list[OfferView] = [];
    visible_zones = workspace.zones if workspace is not None else [];
    if workspace is not None {
        active_offers = [o for o in workspace.offers if o.region == region and o.status == "available"];
        visible_zones = [z for z in workspace.zones if z.region == region];
    }
    current_offer = active_offers[0] if len(active_offers) > 0 else None;
    tracked_zone = workspace.tracked_zone if workspace is not None else start_zone;
    map_center: list[float] = [-0.0, 0.0];
    map_zoom: float = 8.0;
    if len(visible_zones) > 0 {
        for zone in visible_zones { if zone.name == tracked_zone { map_center = [zone.x, zone.y]; } }
        if region == "Sri Lanka" { map_center = [79.8612, 6.9271]; map_zoom = 8.0; }
        elif region == "United Kingdom" { map_center = [-2.0, 53.0]; map_zoom = 5.0; }
        else { map_center = [-98.0, 39.0]; map_zoom = 3.5; }
    }

    if loading { return <main className="min-h-svh bg-muted/30 p-8"><p className="mx-auto max-w-5xl text-sm text-muted-foreground">Loading your simulated driver workspace…</p></main>; }
    if workspace is None { return <main className="min-h-svh bg-muted/30 p-8"><Card className="mx-auto max-w-lg"><CardHeader><CardTitle>Workspace unavailable</CardTitle><CardDescription>{error_message}</CardDescription></CardHeader><CardContent><Button onClick={lambda { nav("/account"); }}>Return to sign in</Button></CardContent></Card></main>; }

    return <main className="min-h-svh bg-muted/30 pb-24 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-[1600px] flex-wrap items-center justify-between gap-3 px-4 py-4 sm:px-6"><div><p className="text-xl font-semibold tracking-tight">HireWise</p><p className="text-sm text-muted-foreground">A clearer view of each simulated shift</p></div><div className="flex items-center gap-2"><Badge variant="secondary">Simulated data</Badge><Button variant="outline" size="sm" onClick={sign_out}>Sign out</Button></div></div></header>
        <div className="mx-auto max-w-[1600px] space-y-5 px-4 py-5 sm:px-6">
            {notice and <p role="status" className="rounded-xl border border-primary/20 bg-primary/5 px-4 py-3 text-sm">{notice}</p>}
            {error_message and <p role="alert" className="rounded-xl border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">{error_message}</p>}
            <div className="grid items-start gap-5 xl:grid-cols-[minmax(280px,0.85fr)_minmax(360px,1.2fr)_minmax(300px,0.9fr)]">
                <Card className="rounded-2xl shadow-sm"><CardHeader><CardTitle>Shift and vehicle</CardTitle><CardDescription>Set priorities before reviewing offers.</CardDescription></CardHeader><CardContent className="space-y-4">
                    <label className="block space-y-1.5 text-sm font-medium">Region<select value={region} onChange={on_region} className="h-10 w-full rounded-lg border bg-background px-3"><option value="Sri Lanka">Sri Lanka</option><option value="United Kingdom">United Kingdom (development paused)</option><option value="United States">USA (development paused)</option></select></label>
                    {region != "Sri Lanka" and <p className="rounded-lg border border-amber-300/50 bg-amber-50 px-3 py-2 text-xs leading-relaxed text-amber-900">UK and USA options are retained, but their data and routes are paused. Sri Lanka simulated data is available.</p>}
                    <label className="block space-y-1.5 text-sm font-medium">Shift goals<textarea value={goals_text} onChange={on_goals} placeholder="4 hours, Rs. 4,500 net, home by 1:00 PM" className="min-h-20 w-full rounded-lg border bg-background px-3 py-2 text-sm" /></label>
                    <div className="grid grid-cols-2 gap-3"><label className="space-y-1 text-xs font-medium">Start zone<select value={start_zone} onChange={on_start} className="h-10 w-full rounded-lg border bg-background px-2 text-sm">{for z in visible_zones { <option key={z.name} value={z.name}>{z.name}</option> }}</select></label><label className="space-y-1 text-xs font-medium">Home zone<select value={home_zone} onChange={on_home} className="h-10 w-full rounded-lg border bg-background px-2 text-sm">{for z in visible_zones { <option key={z.name} value={z.name}>{z.name}</option> }}</select></label></div>
                    <div className="grid grid-cols-2 gap-3"><label className="space-y-1 text-xs font-medium">Shift hours<Input type="number" min="0.5" step="0.5" value={shift_hours} onChange={on_hours}/></label><label className="space-y-1 text-xs font-medium">Net target (LKR)<Input type="number" min="0" value={target_profit} onChange={on_target}/></label></div>
                    <label className="block space-y-1.5 text-sm font-medium">Home deadline<Input type="time" value={deadline} onChange={on_deadline}/></label>
                    <label className="block space-y-1.5 text-sm font-medium">Vehicle<select value={vehicle_type} onChange={on_vehicle} className="h-10 w-full rounded-lg border bg-background px-3"><option value="petrol">Petrol</option><option value="ev">Electric</option></select></label>
                    {vehicle_type == "petrol" and <div className="grid grid-cols-2 gap-3"><label className="space-y-1 text-xs font-medium">Fuel efficiency (km/L)<Input type="number" min="0.1" step="0.1" value={fuel_efficiency} onChange={on_efficiency}/></label><label className="space-y-1 text-xs font-medium">Fuel price (LKR/L)<Input type="number" min="0" value={fuel_price} onChange={on_fuel_price}/></label></div>}
                    <div className="grid grid-cols-2 gap-2"><Button variant="outline" disabled={busy or not goals_text} onClick={parse_goals}>Parse goals</Button><Button disabled={busy} onClick={save_setup}>Save setup</Button></div>
                    <label className="block space-y-1.5 text-sm font-medium">Decision priority<select value={preference} onChange={on_preference} className="h-10 w-full rounded-lg border bg-background px-3"><option value="profit">Net profit</option><option value="route">Shortest ETA</option></select></label>
                </CardContent></Card>

                <div className="space-y-5">
                    <Card className="overflow-hidden rounded-2xl shadow-sm"><CardHeader className="pb-3"><div className="flex flex-wrap items-start justify-between gap-2"><div><CardTitle>Driver map</CardTitle><CardDescription>Map layer is live when configured; zone data is simulated.</CardDescription></div><Badge variant="outline">{region}</Badge></div></CardHeader><CardContent className="space-y-3"><div className="h-[320px] overflow-hidden rounded-xl border bg-muted"><TomTomMap host={map_ref} center={map_center} zoom={map_zoom} onFallback={show_map_message}/></div>{map_message and <p className="rounded-lg bg-muted px-3 py-2 text-xs text-muted-foreground">{map_message}</p>}<p className="text-xs text-muted-foreground">Use the map’s location control to opt in to device location. Your browser may ask permission. No location is saved by this app.</p></CardContent></Card>
                    <Card className="rounded-2xl shadow-sm"><CardHeader><CardTitle>Zone list</CardTitle><CardDescription>Simulated demand by zone; UK/USA data is paused.</CardDescription></CardHeader><CardContent><div className="grid gap-2 sm:grid-cols-2">{for z in visible_zones { <div key={z.name} className="flex items-center justify-between gap-2 rounded-xl border bg-background px-3 py-2.5"><span className="text-sm font-medium">{z.name}</span><span className="text-xs text-muted-foreground">Demand {round((z.demand_morning + z.demand_midday + z.demand_evening) / 3.0 * 100.0)}%</span></div> }}</div>{len(visible_zones) == 0 and <p className="rounded-xl border border-dashed p-4 text-sm text-muted-foreground">No zone data is available for this region yet. UK/USA development is paused.</p>}</CardContent></Card>
                </div>

                <Card className="rounded-2xl shadow-sm"><CardHeader><div className="flex items-center justify-between gap-2"><div><CardTitle>Offer feed</CardTitle><CardDescription>Review one available simulated offer at a time.</CardDescription></div><Badge variant="secondary">{len(active_offers)} available</Badge></div></CardHeader><CardContent className="space-y-4">
                    {current_offer is not None and <div className="space-y-4"><div className="rounded-xl border bg-muted/35 p-4"><div className="flex items-start justify-between gap-3"><div><p className="font-semibold">{current_offer.pickup} to {current_offer.dropoff}</p><p className="mt-1 text-sm text-muted-foreground">{current_offer.distance_km} km · {current_offer.duration_min} min estimated</p></div><Badge>{current_offer.evaluation.recommendation}</Badge></div><p className="mt-4 text-2xl font-semibold">LKR {round(current_offer.fare + current_offer.surge)}</p>{current_offer.surge > 0.0 and <p className="text-xs font-medium text-amber-700">Includes LKR {round(current_offer.surge)} simulated surge</p>}</div>
                    <div className="space-y-2 rounded-xl border p-4"><p className="text-sm font-semibold">HireWise recommendation: {current_offer.evaluation.recommendation}</p><p className="text-sm leading-relaxed text-muted-foreground">{current_offer.evaluation.reason}</p><div className="grid grid-cols-2 gap-x-2 gap-y-1 pt-1 text-xs text-muted-foreground"><span>Estimated net</span><span className="text-right">LKR {round(current_offer.evaluation.trip_net)}</span><span>Return demand</span><span className="text-right">{round(current_offer.evaluation.demand * 100.0)}%</span><span>Est. time home</span><span className="text-right">{round(current_offer.evaluation.home_eta)} min</span></div></div>
                    <div className="grid grid-cols-2 gap-2"><Button disabled={busy} onClick={lambda { decide(current_offer.id, "accept"); }}>Accept offer</Button><Button variant="outline" disabled={busy} onClick={lambda { decide(current_offer.id, "decline"); }}>Decline offer</Button></div><Button variant="ghost" className="w-full" disabled={busy} onClick={lambda { decide(current_offer.id, "decline"); }}>Next offer</Button></div>}
                    {current_offer is None and <div className="rounded-xl border border-dashed px-4 py-8 text-center"><p className="font-medium">No available offers</p><p className="mt-1 text-sm text-muted-foreground">All offers were reviewed, or this region’s data is paused.</p></div>}
                    {current_offer is not None and <div className="space-y-3 rounded-xl border bg-background p-4"><div><p className="font-semibold">What-if scenario</p><p className="text-xs text-muted-foreground">Simulated assumption: Rain multiplies traffic by 1.25×; not live weather or traffic.</p></div><div className="grid grid-cols-2 gap-2"><label className="space-y-1 text-xs font-medium">Weather<select value={weather} onChange={on_weather} className="h-10 w-full rounded-lg border bg-background px-2"><option value="clear">Clear</option><option value="rain">Rain</option></select></label><label className="space-y-1 text-xs font-medium">Time band<select value={time_band} onChange={on_time_band} className="h-10 w-full rounded-lg border bg-background px-2"><option value="morning">Morning peak</option><option value="midday">Midday</option><option value="evening">Evening peak</option></select></label></div><Button variant="outline" disabled={busy} onClick={lambda { evaluate_scenario(current_offer.id); }}>Re-evaluate current offer</Button>{scenario is not None and <div className="rounded-lg bg-muted/50 p-3 text-sm"><p className="font-medium">Scenario: {scenario.recommendation}{" (recommendation changed)" if scenario.changed else " (unchanged)"}</p><p className="mt-1 text-muted-foreground">{scenario.reason}</p><p className="mt-1 text-xs text-muted-foreground">Estimated home ETA {round(scenario.home_eta)} min · simulated net LKR {round(scenario.trip_net)}</p></div>}</div>}
                    <div className="border-t pt-4"><Button variant="outline" className="w-full" disabled={busy} onClick={compare_shift}>Simulate full shift</Button>{compare is not None and <div className="mt-3 grid grid-cols-2 gap-3"><div className="rounded-xl border bg-muted/40 p-3"><p className="text-xs font-semibold">Highest fare first</p><p className="mt-2 text-sm">Net LKR {round(compare.naive_profit)}</p><p className="text-xs text-muted-foreground">Home ETA {round(compare.naive_home_eta)} min</p></div><div className="rounded-xl border bg-primary/5 p-3"><p className="text-xs font-semibold">HireWise agent</p><p className="mt-2 text-sm">Net LKR {round(compare.agent_profit)}</p><p className="text-xs text-muted-foreground">Home ETA {round(compare.agent_home_eta)} min</p></div></div>}</div>
                    <div className="border-t pt-4"><div className="flex items-center justify-between gap-2"><p className="font-semibold">Passenger requests</p><Button variant="ghost" size="sm" onClick={refresh_requests}>Refresh</Button></div>{len(passenger_requests) == 0 and <p className="mt-2 rounded-lg border border-dashed p-3 text-sm text-muted-foreground">No passenger requests yet.</p>}{for request in passenger_requests { <div key={request.pickup + "-" + request.dropoff + "-" + request.time_band} className="mt-2 rounded-lg border bg-muted/30 p-3"><p className="text-sm font-medium">{request.pickup} to {request.dropoff}</p><p className="text-xs text-muted-foreground">{request.time_band} · {request.distance_km} km · LKR {round(request.fare_lkr)} · {round(request.eta_min)} min estimated · simulated</p></div>}}</div>
                </CardContent></Card>
            </div>
        </div>
        <footer className="fixed inset-x-0 bottom-0 z-20 border-t bg-background/95 shadow-[0_-8px_24px_rgba(15,23,42,0.06)] backdrop-blur"><div className="mx-auto grid max-w-[1600px] grid-cols-2 gap-3 px-4 py-3 sm:grid-cols-4 sm:px-6"><div><p className="text-[11px] text-muted-foreground">Shift progress</p><p className="text-sm font-semibold">{len(workspace.decisions)} decisions</p></div><div><p className="text-[11px] text-muted-foreground">Accepted net</p><p className="text-sm font-semibold">LKR {round(sum([d.amount for d in workspace.decisions if d.decision == "accept"]))}</p></div><div><p className="text-[11px] text-muted-foreground">Time used</p><p className="text-sm font-semibold">{round(sum([d.minutes for d in workspace.decisions if d.decision == "accept"]))} min</p></div><div><p className="text-[11px] text-muted-foreground">Current simulated zone</p><p className="text-sm font-semibold">{tracked_zone}</p></div></div></footer>
    </main>;
}
