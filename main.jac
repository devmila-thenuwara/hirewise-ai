import from services.driverService { parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, evaluateOffer, getOfferExplanation, getShiftComparison }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from .components.DriverWorkspace { DriverWorkspace }

def:pub app() -> JsxElement {
    return <Router><Routes><Route path="/" element={<DriverWorkspace />} /></Routes></Router>;
}
