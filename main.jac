import from services.accountService { saveDriverProfile, getDriverProfile, getCurrentAccount, DriverProfileView }
import from services.driverService { parseGoals, getDriverWorkspace, saveDriverSetup, decideOffer, getShiftComparison, evaluateOfferScenario, getPassengerRequests, WorkspaceView, OfferView, ShiftComparisonView, ScenarioView }
import from services.passengerService { getPassengerOptions, createPassengerRequest, PassengerOptionsView, PassengerRouteOption, PassengerRequestView }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, AuthGuard }

cl {
    import from .components.DriverAccount { DriverAccount }
    import from .components.DriverWorkspace { DriverWorkspace }
    import from .components.PassengerBooking { PassengerBooking }

    def:pub app() -> JsxElement {
        return <Router><Routes><Route path="/account" element={<DriverAccount />} /><Route path="/" element={<AuthGuard redirect="/account"><DriverWorkspace /></AuthGuard>} /><Route path="/passenger" element={<AuthGuard redirect="/account"><PassengerBooking /></AuthGuard>} /></Routes></Router>;
    }
}
