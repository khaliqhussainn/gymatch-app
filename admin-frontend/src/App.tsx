import { BrowserRouter as Router, Routes, Route } from "react-router";
import { Toaster } from 'react-hot-toast';
import SignIn from "./pages/AuthPages/SignIn";
import SignUp from "./pages/AuthPages/SignUp";
import NotFound from "./pages/OtherPage/NotFound";
import UserProfiles from "./pages/UserProfiles";
import Videos from "./pages/UiElements/Videos";
import Images from "./pages/UiElements/Images";
import Alerts from "./pages/UiElements/Alerts";
import Badges from "./pages/UiElements/Badges";
import Avatars from "./pages/UiElements/Avatars";
import Buttons from "./pages/UiElements/Buttons";
import LineChart from "./pages/Charts/LineChart";
import BarChart from "./pages/Charts/BarChart";
import Calendar from "./pages/Calendar";
import BasicTables from "./pages/Tables/BasicTables";
import FormElements from "./pages/Forms/FormElements";
import Blank from "./pages/Blank";
import AppLayout from "./layout/AppLayout";
import { ScrollToTop } from "./components/common/ScrollToTop";
import Home from "./pages/Dashboard/Home";
import AdminSignIn from "./pages/AuthPages/AdminSignIn";
import AdminDashboard from "./pages/Admin/Dashboard/AdminDashboard";
import GymList from "./pages/Admin/Gyms/GymList";
import GymForm from "./pages/Admin/Gyms/GymForm";
import UserList from "./pages/Admin/Users/UserList";
import CategoryList from "./pages/Admin/Categories/CategoryList";
import TagList from "./pages/Admin/Categories/TagList";
import AmenityList from "./pages/Admin/Categories/AmenityList";
import FeatureRequestList from "./pages/Admin/FeatureRequests/FeatureRequestList";
import ProtectedRoute from "./components/auth/ProtectedRoute";


export default function App() {
  return (
    <>
      <Router>
        <Toaster
          position="top-right"
          reverseOrder={false}
          containerStyle={{
            top: 80,
            zIndex: 99999,
          }}
        />
        <ScrollToTop />
        <Routes>
          {/* Dashboard Layout */}
          <Route element={<ProtectedRoute><AppLayout /></ProtectedRoute>}>
            <Route index path="/home" element={<Home />} />

            {/* Others Page */}
            <Route path="/profile" element={<UserProfiles />} />
            <Route path="/calendar" element={<Calendar />} />
            <Route path="/blank" element={<Blank />} />

            {/* Forms */}
            <Route path="/form-elements" element={<FormElements />} />

            {/* Tables */}
            <Route path="/basic-tables" element={<BasicTables />} />

            {/* Ui Elements */}
            <Route path="/alerts" element={<Alerts />} />
            <Route path="/avatars" element={<Avatars />} />
            <Route path="/badge" element={<Badges />} />
            <Route path="/buttons" element={<Buttons />} />
            <Route path="/images" element={<Images />} />
            <Route path="/videos" element={<Videos />} />

            {/* Charts */}
            <Route path="/line-chart" element={<LineChart />} />
            <Route path="/bar-chart" element={<BarChart />} />
            {/* GYMatch Admin Routes */}
            <Route path="/" element={<AdminDashboard />} />
            <Route path="/gyms" element={<GymList />} />
            <Route path="/gyms/add" element={<GymForm />} />
            <Route path="/gyms/edit/:id" element={<GymForm />} />
            <Route path="/users" element={<UserList />} />
            <Route path="/categories" element={<CategoryList />} />
            <Route path="/tags" element={<TagList />} />
            <Route path="/amenities" element={<AmenityList />} />
            <Route path="/feature-requests" element={<FeatureRequestList />} />

          </Route>

          {/* Auth Layout */}
          <Route path="/signin2" element={<SignIn />} />
          <Route path="/signin" element={<AdminSignIn />} />
          <Route path="/signup" element={<SignUp />} />

          {/* Fallback Route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Router>
    </>
  );
}
