import React from 'react';
import {
    GridIcon,
    CalenderIcon,
    UserCircleIcon,
    ListIcon,
    TableIcon,
    PageIcon,
    ChatIcon,
    GroupIcon,
    TaskIcon,
    PieChartIcon,
    BoxCubeIcon,
    PlugInIcon,
} from "../icons";

export type NavSubItem = {
    name: string;
    path: string;
    pro?: boolean;
    new?: boolean;
};

export type NavItem = {
    name: string;
    icon: React.ReactNode;
    path?: string;
    subItems?: NavSubItem[];
};

export const navItems: NavItem[] = [
    {
        icon: <GridIcon />,
        name: "Dashboard",
        subItems: [{ name: "Ecommerce", path: "/", pro: false }],
    },
    {
        icon: <CalenderIcon />,
        name: "Calendar",
        path: "/calendar",
    },
    {
        icon: <UserCircleIcon />,
        name: "User Profile",
        path: "/profile",
    },
    {
        name: "Forms",
        icon: <ListIcon />,
        subItems: [{ name: "Form Elements", path: "/form-elements", pro: false }],
    },
    {
        name: "Tables",
        icon: <TableIcon />,
        subItems: [{ name: "Basic Tables", path: "/basic-tables", pro: false }],
    },
    {
        name: "Pages",
        icon: <PageIcon />,
        subItems: [
            { name: "Blank Page", path: "/blank", pro: false },
            { name: "404 Error", path: "/error-404", pro: false },
        ],
    },
    {
        icon: <ChatIcon />,
        name: "Chat",
        path: "/chat",
    },
];

export const adminItems: NavItem[] = [
    {
        icon: <GridIcon />,
        name: "Dashboard",
        path: "/",
    },
    {
        icon: <UserCircleIcon />,
        name: "Users",
        path: "/users",
    },
    {
        icon: <GroupIcon />,
        name: "Gyms",
        path: "/gyms",
    },
    {
        icon: <TaskIcon />,
        name: "Gyms Categories",
        path: "/categories",
    },
    {
        icon: <BoxCubeIcon />,
        name: "Location Preferences",
        path: "/location-preferences",
    },
    {
        icon: <PieChartIcon />,
        name: "Feature Requests",
        path: "/feature-requests",
    },
];

export const othersItems: NavItem[] = [
    {
        icon: <PieChartIcon />,
        name: "Charts",
        subItems: [
            { name: "Line Chart", path: "/line-chart", pro: false },
            { name: "Bar Chart", path: "/bar-chart", pro: false },
        ],
    },
    {
        icon: <BoxCubeIcon />,
        name: "UI Elements",
        subItems: [
            { name: "Alerts", path: "/alerts", pro: false },
            { name: "Avatar", path: "/avatars", pro: false },
            { name: "Badge", path: "/badge", pro: false },
            { name: "Buttons", path: "/buttons", pro: false },
            { name: "Images", path: "/images", pro: false },
            { name: "Videos", path: "/videos", pro: false },
        ],
    },
    {
        icon: <PlugInIcon />,
        name: "Authentication",
        subItems: [
            { name: "Sign In", path: "/signin", pro: false },
            { name: "Sign Up", path: "/signup", pro: false },
        ],
    },
];
