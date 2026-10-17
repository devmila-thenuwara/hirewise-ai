sv import from ..services.passengerService { PassengerOptionsView, PassengerRouteOption, getPassengerOptions, createPassengerRequest }
sv import from ..services.accountService { getCurrentAccount, DriverProfileView }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.badge { Badge }
import from "@jac/runtime" { jacLogout, useNavigate }

def:pub PassengerBooking() -> JsxElement {
    has pickup: str = "Moratuwa";
    has dropoff: str = "Colombo Fort";
    has time_band: str = "midday";
    has options: PassengerOptionsView | None = None;
    has route_options: list[PassengerRouteOption] = [];
    has selected: str = "fastest";
    has error_message: str = "";
    has notice: str = "";
    has busy: bool = False;
    has loaded: bool = False;
    nav = useNavigate();

    async can with entry {
        account: DriverProfileView | None = None;
        try {
            account = await getCurrentAccount();
            if account is None or account.role != "passenger" { nav("/"); }
        } except Exception { nav("/account"); }
    }

    def on_pickup(e: ChangeEvent) { pickup = e.target.value; loaded = False; route_options = []; }
    def on_dropoff(e: ChangeEvent) { dropoff = e.target.value; loaded = False; route_options = []; }
    def on_band(e: ChangeEvent) { time_band = e.target.value; loaded = False; route_options = []; }

    async def load_options -> None {
        busy = True; error_message = ""; notice = "";
        try {
            result: PassengerOptionsView | None = await getPassengerOptions(pickup, dropoff, time_band);
            if result is not None { options = result; route_options = result.options; loaded = True; }
            else { loaded = False; route_options = []; }
        }
        except Exception { error_message = "Could not calculate options. Confirm you are signed in with a passenger account."; }
        busy = False;
    }

    async def request_ride -> None {
        busy = True; error_message = ""; notice = "";
        try {
            result = await createPassengerRequest(pickup, dropoff, time_band, selected);
            if result.ok { notice = result.message; }
            else { error_message = result.message; }
        } except Exception { error_message = "Could not create the simulated ride request."; }
        busy = False;
    }

    async def sign_out -> None { await jacLogout(); nav("/account"); }

    zones: list[str] = ["Moratuwa", "Colombo Fort", "Dehiwala", "Nugegoda", "Maharagama", "Negombo", "Galle", "Kandy"];
    can_request = len(route_options) > 0 and (selected == "fastest" or selected == "cheapest" or selected == "least_traffic");

    return <main className="min-h-svh bg-muted/30 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3 px-4 py-4 sm:px-6"><div><p className="text-xl font-semibold">HireWise</p><p className="text-sm text-muted-foreground">Passenger route options</p></div><div className="flex items-center gap-2"><Badge variant="secondary">Simulated data</Badge><Button variant="outline" size="sm" onClick={lambda { nav("/"); }}>Driver workspace</Button><Button variant="outline" size="sm" onClick={sign_out}>Sign out</Button></div></div></header>
        <div className="mx-auto max-w-5xl space-y-5 px-4 py-6 sm:px-6">
            {notice and <p role="status" className="rounded-xl border border-primary/20 bg-primary/5 px-4 py-3 text-sm">{notice}</p>}
            {error_message and <p role="alert" className="rounded-xl border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">{error_message}</p>}
            <Card className="rounded-2xl shadow-sm"><CardHeader><CardTitle>Plan a Sri Lanka ride</CardTitle><CardDescription>Choose a trip to compare illustrative routes, fare estimates, and ETAs. No live routing is used.</CardDescription></CardHeader><CardContent className="grid gap-4 sm:grid-cols-3">
                <label className="space-y-1.5 text-sm font-medium">Pickup zone<select value={pickup} onChange={on_pickup} className="h-11 w-full rounded-lg border bg-background px-3">{for zone in zones { <option key={zone} value={zone}>{zone}</option> }}</select></label>
                <label className="space-y-1.5 text-sm font-medium">Drop-off zone<select value={dropoff} onChange={on_dropoff} className="h-11 w-full rounded-lg border bg-background px-3">{for zone in zones { <option key={zone} value={zone}>{zone}</option> }}</select></label>
                <label className="space-y-1.5 text-sm font-medium">Time band<select value={time_band} onChange={on_band} className="h-11 w-full rounded-lg border bg-background px-3"><option value="morning">Morning peak</option><option value="midday">Midday</option><option value="evening">Evening peak</option></select></label>
                <div className="sm:col-span-3"><Button disabled={busy} onClick={load_options}>Compare route options</Button></div>
            </CardContent></Card>
            {loaded and <section className="space-y-4"><div className="grid gap-4 md:grid-cols-3">{for option in route_options { <Card key={option.kind} className="rounded-2xl shadow-sm"><CardHeader><CardTitle className="text-lg">{option.label}</CardTitle><CardDescription>{option.distance_km} km simulated</CardDescription></CardHeader><CardContent className="space-y-3"><p className="text-2xl font-semibold">LKR {round(option.fare_lkr)}</p><p className="text-sm">Estimated ETA: {round(option.eta_min)} min</p><p className="text-sm leading-relaxed text-muted-foreground">{option.explanation}</p><Button variant={selected == option.kind and "default" or "outline"} onClick={lambda { selected = option.kind; }}>Choose {option.label}</Button></CardContent></Card> }}</div><p className="rounded-xl border bg-amber-50 px-4 py-3 text-sm text-amber-950">All distances, time-band factors, fares, and ETAs are simulated assumptions. The cheapest option remains visible.</p><Button disabled={busy or not can_request} onClick={request_ride}>Request ride</Button></section>}
            {not loaded and <Card className="rounded-2xl border-dashed"><CardContent className="py-10 text-center"><p className="font-medium">Compare before requesting</p><p className="mt-1 text-sm text-muted-foreground">Three route styles will be shown with fares and ETAs.</p></CardContent></Card>}
        </div>
    </main>;
}
