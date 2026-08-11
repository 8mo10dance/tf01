import React, { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import Top from "./pages/Top";
import Users from "./pages/Users";
import UsersNew from "./pages/UsersNew";

document.addEventListener("DOMContentLoaded", () => {
  const app = document.getElementById("app");
  if (app === null) return;

  const root = createRoot(app);
  root.render(<App />);
});

const router = createBrowserRouter([
  {
    path: "/",
    element: <Top />,
  },
  {
    path: "/users",
    element: <Users />,
  },
  {
    path: "/users/new",
    element: <UsersNew />,
  },
]);

function App() {
  return (
    <StrictMode>
      <RouterProvider router={router} />
    </StrictMode>
  );
}
