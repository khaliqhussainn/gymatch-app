import PageMeta from "../../components/common/PageMeta";
import AuthLayout from "./AuthPageLayout";
import AdminSignInForm from "../../components/auth/AdminSignInForm";

export default function AdminSignIn() {
    return (
        <>
            <PageMeta
                title="Admin Sign In | Property Management"
                description="Admin Sign In"
            />
            {/* <AuthLayout> */}
            <div className="my-auto flex justify-center items-center min-h-screen">
                <AdminSignInForm />
                </div>
            {/* </AuthLayout> */}
        </>
    );
}
