import { AppBar, Box, Button, Tab, Tabs, Toolbar, Typography } from '@mui/material';
import { Outlet, useLocation, useNavigate } from 'react-router';
import { useAuth } from '../auth/AuthContext';

const TABS = [
  { path: '/meters', label: 'Meters' },
  { path: '/readings', label: 'Readings' },
];

export function AppLayout() {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const activeTab = TABS.find((tab) => location.pathname.startsWith(tab.path))?.path ?? false;

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Grid Meter
          </Typography>
          <Tabs value={activeTab} textColor="inherit" indicatorColor="secondary">
            {TABS.map((tab) => (
              <Tab key={tab.path} value={tab.path} label={tab.label} onClick={() => navigate(tab.path)} />
            ))}
          </Tabs>
          <Button color="inherit" onClick={logout} sx={{ ml: 2 }}>
            Log out
          </Button>
        </Toolbar>
      </AppBar>
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Outlet />
      </Box>
    </Box>
  );
}
