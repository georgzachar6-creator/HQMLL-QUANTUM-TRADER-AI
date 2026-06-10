import React from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';
import App from './App';
import RouteErrorPage from './pages/RouteErrorPage';
import Dashboard from './pages/Dashboard';
import Connections from './pages/Connections';
import QmlLab from './pages/QmlLab';
import Markets from './pages/Markets';
import Settings from './pages/Settings';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    errorElement: <RouteErrorPage />,
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: 'dashboard', element: <Dashboard /> },
      { path: 'connections', element: <Connections /> },
      { path: 'qml-lab', element: <QmlLab /> },
      { path: 'markets', element: <Markets /> },
      { path: 'settings', element: <Settings /> },
    ],
  },
]);
