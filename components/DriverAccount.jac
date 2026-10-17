import from "@jac/runtime" { jacLogin, jacSignup, jacIsLoggedIn, useNavigate }
sv import from ..services.accountService { saveDriverProfile }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.badge { Badge }

 def:pub DriverAccount() -> JsxElement {
    has email: str = "";
    has phone: str = "";
    has password: str = "";
    has mode: str = "login";
    has error_message: str = "";
    has loading: bool = False;
    nav = useNavigate();

    def handle_email(e: ChangeEvent) { email = e.target.value; }
    def handle_phone(e: ChangeEvent) { phone = e.target.value; }
    def handle_password(e: ChangeEvent) { password = e.target.value; }
    def toggle_mode(e: MouseEvent) { mode = "signup" if mode == "login" else "login"; error_message = ""; }
    handle_title = "Welcome back" if mode == "login" else "Create your driver account";
    handle_subtitle = "Sign in to plan your next shift." if mode == "login" else "Add your contact details and choose a password.";
    password_label = "Your password" if mode == "login" else "At least 8 characters";
    submit_label = "Sign in" if mode == "login" else "Create driver account";
    switch_label = "New to HireWise? Create an account" if mode == "login" else "Already have an account? Sign in";

    async def handle_login -> None {
        if mode == "signup" { await handle_signup(); return; }
        loading = True;
        error_message = "";
        ok: bool = False;
        try {
            ok = await jacLogin(email, password);
            if ok { nav("/"); }
            else { error_message = "Sign-in failed. Check your email and password."; }
        } except Exception { error_message = "Sign-in failed. Check your details and try again."; }
        loading = False;
    }

    async def handle_signup -> None {
        loading = True;
        error_message = "";
        signup_result: dict | None = None;
        login_ok: bool = False;
        profile_result: any = None;
        try {
            if not email.strip() or not phone.strip() or len(password) < 8 {
                error_message = "Enter your email, phone, and a password of at least 8 characters.";
                loading = False;
                return;
            }
            signup_result = await jacSignup(email, password);
            if not (signup_result["success"] as bool) {
                error_message = str(signup_result["error"] or "Account registration failed.");
                loading = False;
                return;
            }
            login_ok = await jacLogin(email, password);
            if not login_ok {
                error_message = "Account created. Sign in with your new password to continue.";
                mode = "login";
                loading = False;
                return;
            }
            profile_result = await saveDriverProfile(email, phone);
            nav("/");
        } except Exception {
            error_message = "Could not complete registration. If the account already exists, sign in instead.";
        }
        loading = False;
    }

    async can with entry {
        if jacIsLoggedIn() { nav("/"); }
    }

    return <div className="grid min-h-svh bg-muted/40 lg:grid-cols-[1.05fr_0.95fr]">
        <section className="relative hidden overflow-hidden bg-primary p-10 text-primary-foreground lg:flex lg:flex-col lg:justify-between">
            <div className="absolute -right-24 -top-24 size-96 rounded-full bg-primary-foreground/10 blur-3xl" />
            <div className="relative flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 text-lg font-bold">H</div><div><p className="text-lg font-semibold">HireWise</p><p className="text-sm text-primary-foreground/75">Driver decision workspace</p></div></div>
            <div className="relative max-w-xl"><Badge variant="outline" className="mb-5 border-primary-foreground/30 text-primary-foreground">Sri Lanka · United Kingdom · United States</Badge><h1 className="text-balance text-4xl font-semibold leading-tight tracking-tight">Drive each shift with a clearer plan.</h1><p className="mt-4 max-w-lg text-primary-foreground/80">Compare simulated ride offers against your costs, route priority and home-time goal.</p></div>
            <p className="relative text-xs text-primary-foreground/75">Offers and driver data are simulated. Route and traffic services are introduced in a later phase.</p>
        </section>
        <section className="flex min-h-svh items-center justify-center p-4 sm:p-8">
            <Card className="w-full max-w-md shadow-lg"><CardHeader><div className="mb-2 flex items-center gap-3 lg:hidden"><div className="flex size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground font-bold">H</div><span className="font-semibold">HireWise</span></div><CardTitle>{handle_title}</CardTitle><CardDescription>{handle_subtitle}</CardDescription></CardHeader><CardContent className="flex flex-col gap-4">
                {error_message and <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">{error_message}</p>}
                <label className="flex flex-col gap-1.5 text-sm font-medium">Email<Input type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={handle_email}/></label>
                {mode == "signup" and <label className="flex flex-col gap-1.5 text-sm font-medium">Phone number<Input type="tel" autoComplete="tel" placeholder="Your phone number" value={phone} onChange={handle_phone}/></label>}
                <label className="flex flex-col gap-1.5 text-sm font-medium">Password<Input type="password" autoComplete="current-password" placeholder={password_label} value={password} onChange={handle_password}/></label>
                <Button disabled={loading} className="w-full" onClick={handle_login}>{submit_label}</Button>
                <button type="button" className="text-sm font-medium text-primary underline-offset-4 hover:underline" onClick={toggle_mode}>{switch_label}</button>
                <p className="text-xs leading-relaxed text-muted-foreground">Your password is handled by Jac's built-in authentication. HireWise does not store it in your profile.</p>
            </CardContent></Card>
        </section>
    </div>;
}
