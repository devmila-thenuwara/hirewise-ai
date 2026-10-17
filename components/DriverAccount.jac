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
    def toggle_mode(e: MouseEvent) {
        mode = "signup" if mode == "login" else "login";
        error_message = "";
    }

    title_text = "Welcome back" if mode == "login" else "Create your driver account";
    subtitle_text = "Sign in to plan your next shift." if mode == "login" else "Add your contact details and choose a password.";
    password_hint = "Your password" if mode == "login" else "At least 8 characters";
    submit_text = "Sign in" if mode == "login" else "Create driver account";
    switch_text = "New to HireWise? Create an account" if mode == "login" else "Already have an account? Sign in";

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

    return <main className="relative isolate flex min-h-svh w-full items-center justify-center overflow-hidden bg-slate-950 px-4 py-8 text-white sm:px-8">
        <div className="absolute inset-0 -z-20 bg-[linear-gradient(180deg,#728a9a_0%,#566c7d_28%,#334859_51%,#152938_72%,#07141f_100%)]" />
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_at_52%_34%,rgba(244,172,137,0.30),transparent_34%),linear-gradient(90deg,rgba(3,12,21,0.62),transparent_58%,rgba(3,12,21,0.18))]" />
        <svg className="absolute inset-0 -z-10 h-full w-full" viewBox="0 0 1440 960" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Illustrated dusk skyline and river bridge">
            <defs>
                <linearGradient id="riverNight" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#142b38"/><stop offset="1" stopColor="#06111b"/></linearGradient>
                <linearGradient id="glassSkyline" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#263b4b"/><stop offset="1" stopColor="#101e2b"/></linearGradient>
                <filter id="cityGlow"><feGaussianBlur stdDeviation="5"/></filter>
            </defs>
            <path d="M0 520 Q340 475 720 520 T1440 500 L1440 960 L0 960Z" fill="url(#riverNight)" opacity=".78"/>
            <path d="M0 523 Q340 478 720 523 T1440 503" fill="none" stroke="#c7d4d9" strokeOpacity=".35" strokeWidth="3"/>
            <g fill="url(#glassSkyline)" stroke="#b8c8d1" strokeOpacity=".17" strokeWidth="2">
                <path d="M0 330h92v205H0z M96 368h78v163H96z M178 305h122v225H178z M310 275h68v255h-68z M386 220h112v315H386z M505 332h88v201h-88z M600 258h95v278h-95z M704 171h126v367H704z M838 294h92v244h-92z M938 236h73v301h-73z M1019 322h125v215h-125z M1152 267h78v269h-78z M1238 344h92v195h-92z M1336 290h104v249h-104z"/>
            </g>
            <path d="M762 173V78h11V24h7v54h10v95" fill="#273947" stroke="#d7c9bd" strokeOpacity=".45" strokeWidth="3"/>
            <path d="M766 166V94h17v72" fill="#e9a77b" opacity=".28" filter="url(#cityGlow)"/>
            <g fill="#f6bd83" opacity=".82">
                <path d="M25 355h8v7h-8z M52 383h8v7h-8z M113 389h8v8h-8z M142 416h8v8h-8z M204 330h9v8h-9z M236 359h8v8h-8z M273 394h8v8h-8z M326 302h8v8h-8z M352 344h8v8h-8z M405 245h8v9h-8z M445 284h10v8h-10z M469 326h9v9h-9z M519 358h8v8h-8z M556 397h8v8h-8z M615 284h8v8h-8z M656 326h9v9h-9z M719 198h10v9h-10z M753 223h10v9h-10z M801 274h10v10h-10z M850 324h8v8h-8z M901 314h8v8h-8z M952 263h9v8h-9z M981 304h9v8h-9z M1043 349h9v8h-9z M1091 401h9v8h-9z M1170 291h8v8h-8z M1206 333h8v8h-8z M1260 367h9v9h-9z M1362 315h10v9h-10z M1402 368h9v9h-9z"/>
            </g>
            <g fill="none" stroke="#f2ab76" strokeOpacity=".35" strokeWidth="2">
                <path d="M0 615 Q210 570 416 619 T825 622 T1440 586"/><path d="M0 689 Q230 646 455 690 T920 695 T1440 654"/><path d="M0 781 Q270 740 560 784 T1100 786 T1440 751"/><path d="M0 871 Q310 831 640 875 T1200 873 T1440 846"/>
            </g>
            <g fill="none" stroke="#263d49" strokeWidth="18">
                <path d="M-40 604 Q284 530 640 585 T1480 548"/><path d="M80 960 292 570 M330 960 450 576"/>
            </g>
            <g fill="none" stroke="#f1b785" strokeOpacity=".58" strokeWidth="3">
                <path d="M-40 590 Q284 516 640 571 T1480 534"/><path d="M80 960 292 570 M330 960 450 576"/><path d="M287 574v257 M447 580v255"/>
            </g>
            <path d="M0 710 Q225 664 457 710 T930 716 T1440 677" fill="none" stroke="#f89a55" strokeOpacity=".52" strokeWidth="5" filter="url(#cityGlow)"/>
            <rect x="0" y="0" width="1440" height="960" fill="#07111b" opacity=".18"/>
        </svg>
        <div className="pointer-events-none absolute inset-0 -z-10 bg-gradient-to-t from-slate-950/65 via-transparent to-slate-900/5" />

        <div className="absolute left-5 top-5 flex items-center gap-3 sm:left-8 sm:top-7">
            <div className="flex size-11 items-center justify-center rounded-2xl border border-white/35 bg-white/15 text-lg font-bold shadow-lg shadow-black/10 backdrop-blur-xl">H</div>
            <div><p className="text-lg font-semibold tracking-tight text-white">HireWise</p><p className="text-xs text-white/70">Driver decision workspace</p></div>
        </div>

        <div className="relative z-10 grid w-full max-w-6xl items-center gap-10 pt-16 lg:grid-cols-[1.1fr_0.9fr] lg:pt-0">
            <section className="hidden max-w-xl flex-col gap-6 text-white lg:flex">
                <h1 className="text-balance text-5xl font-semibold leading-[1.05] tracking-tight xl:text-6xl">Find a better way through every shift.</h1>
                <p className="max-w-lg text-lg leading-relaxed text-white/75">Plan around your costs, your priorities and the time you need to get home.</p>
                <p className="text-sm text-white/60">Simulated offers and driver position. Route and traffic services are introduced in a later phase.</p>
            </section>

            <Card className="mx-auto w-full max-w-md overflow-hidden rounded-3xl border border-white/35 bg-white/15 text-white shadow-[0_28px_90px_rgba(4,12,22,0.42)] ring-1 ring-white/15 backdrop-blur-2xl supports-[backdrop-filter]:bg-white/10">
                <div className="pointer-events-none absolute inset-x-6 top-0 h-px bg-gradient-to-r from-transparent via-white/85 to-transparent" />
                <CardHeader className="gap-2 px-7 pt-7 sm:px-8 sm:pt-8">
                    <CardTitle className="text-2xl font-semibold tracking-tight text-white">{title_text}</CardTitle>
                    <CardDescription className="text-sm leading-relaxed text-white/70">{subtitle_text}</CardDescription>
                </CardHeader>
                <CardContent className="flex flex-col gap-4 px-7 pb-7 sm:px-8 sm:pb-8">
                    {error_message and <p role="alert" className="rounded-xl border border-red-200/35 bg-red-950/35 px-4 py-3 text-sm text-red-50 backdrop-blur-md">{error_message}</p>}
                    <label className="flex flex-col gap-1.5 text-sm font-medium text-white/90">Email<Input type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={handle_email} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white shadow-inner shadow-black/10 placeholder:text-white/45 focus-visible:border-white/60 focus-visible:ring-white/25"/></label>
                    {mode == "signup" and <label className="flex flex-col gap-1.5 text-sm font-medium text-white/90">Phone number<Input type="tel" autoComplete="tel" placeholder="Your phone number" value={phone} onChange={handle_phone} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white shadow-inner shadow-black/10 placeholder:text-white/45 focus-visible:border-white/60 focus-visible:ring-white/25"/></label>}
                    <label className="flex flex-col gap-1.5 text-sm font-medium text-white/90">Password<Input type="password" autoComplete="current-password" placeholder={password_hint} value={password} onChange={handle_password} className="h-11 rounded-xl border-white/30 bg-slate-950/20 text-white shadow-inner shadow-black/10 placeholder:text-white/45 focus-visible:border-white/60 focus-visible:ring-white/25"/></label>
                    <Button disabled={loading} className="mt-1 h-11 w-full rounded-xl border border-white/20 bg-white/90 font-semibold text-slate-950 shadow-lg shadow-slate-950/20 transition hover:bg-white" onClick={handle_login}>{submit_text}</Button>
                    <button type="button" className="rounded-lg py-1 text-sm font-medium text-white/85 underline-offset-4 transition hover:text-white hover:underline" onClick={toggle_mode}>{switch_text}</button>
                    <div className="mt-1 border-t border-white/20 pt-4"><p className="text-xs leading-relaxed text-white/60">Your password is handled by Jac’s built-in authentication. HireWise does not store it in your profile.</p></div>
                </CardContent>
            </Card>
        </div>
        <div className="pointer-events-none absolute bottom-4 right-5 text-[10px] tracking-wide text-white/40 sm:bottom-5 sm:right-8">CITY LIGHTS · SIMULATED ROUTE DATA</div>
    </main>;
}
