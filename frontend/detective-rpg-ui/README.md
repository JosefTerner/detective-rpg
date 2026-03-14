# Detective RPG UI

## Description
The Detective RPG UI is a React-based frontend for the Detective RPG game. It provides an interactive interface for:
- Navigating the town map
- Investigating crime scenes
- Interviewing witnesses and suspects
- Analyzing evidence
- Accessing the police database
- Submitting case solutions

## Features

### 📋 Case Management
- View active cases
- Track investigation progress
- Submit solutions

### 🗺️ Interactive Map
- Navigate between locations
- Discover clues and evidence
- Track travel time between locations

### 👤 Character Interactions
- Interview witnesses
- Interrogate suspects
- Collaborate with other detectives

### 🔍 Evidence Analysis
- Examine collected evidence
- Connect clues to form theories
- Access forensic tools

### 📊 Dashboard
- Track investigation time
- Monitor score and ranking
- View case history

## Technical Stack
- React 18
- TypeScript
- Redux for state management
- React Router for navigation
- Styled Components for styling
- Leaflet for interactive maps
- Axios for API communication
- Jest and React Testing Library for testing

## Setup and Development

### Prerequisites
- Node.js 16+
- npm or yarn

### Installation
```bash
# Install dependencies
npm install

# Start development server
npm start
```

### Building for Production
```bash
# Create production build
npm run build

# Serve production build locally
npm run serve
```

### Running Tests
```bash
# Run unit tests
npm test

# Run end-to-end tests
npm run e2e
```

## Docker Support
```bash
# Build Docker image
docker build -t detective-rpg/ui .

# Run container
docker run -p 3000:80 detective-rpg/ui
```

## Backend Integration
This UI connects to the Detective RPG backend services through the API Gateway. The connection is configured in the `.env` file:

```
REACT_APP_API_URL=http://localhost:8080
```

## Folder Structure
```
src/
├── components/    # Reusable UI components
├── pages/         # Page-level components
├── store/         # Redux store configuration
├── services/      # API service integrations
├── utils/         # Utility functions
├── assets/        # Static assets
└── tests/         # Test files
```
