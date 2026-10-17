import from services.driverService { parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, getOfferExplanation, getShiftComparison }
import from services.accountService { saveDriverProfile, getDriverProfile }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, AuthGuard }
import from .components.DriverAccount { DriverAccount }
import from .components.DriverWorkspace { DriverWorkspace }

def:pub app() -> JsxElement {
    return <Router><Routes><Route path="/account" element={<DriverAccount />} /><Route path="/" element={<AuthGuard redirect="/account"><DriverWorkspace /></AuthGuard>} /></Routes></Router>;
}
