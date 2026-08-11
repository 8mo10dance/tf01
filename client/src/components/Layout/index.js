import React from "react";

import { NavLink } from "react-router-dom";

export default function Layout({ title, children }) {
  return (
    <div>
      <header>
        <h1>{title}</h1>
        <nav>
          <NavLink to="/">TOP</NavLink>
          <NavLink to="/users">ユーザー一覧</NavLink>
          <NavLink to="/users/new">ユーザー登録</NavLink>
        </nav>
      </header>
      <main>{children}</main>
    </div>
  );
}
