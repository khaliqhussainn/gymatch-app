import { Navigate } from "react-router";
import { adminAuthService } from "../../services/adminAuthService";

interface ProtectedRouteProps {
    children: React.ReactNode;
}

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
    if (!adminAuthService.isAuthenticated()) {
        return <Navigate to="/signin" replace />;
    }

    return <>{children}</>;
}
