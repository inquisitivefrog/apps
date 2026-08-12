import { Box, Typography } from '@mui/material';

export function NotFoundPage() {
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mt: 8 }}>
      <Typography variant="h4">404</Typography>
      <Typography>Page not found.</Typography>
    </Box>
  );
}
