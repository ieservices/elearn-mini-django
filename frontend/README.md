# E-Learning Mini - Frontend

React frontend for the E-Learning Mini application with GraphQL integration.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure the Django backend is running on `http://localhost:8000`

3. Start the development server:
```bash
npm start
```

The application will open at `http://localhost:3000`

## Features

- GraphQL client using Apollo Client
- Course listing with real-time data from the backend
- Responsive design
- Loading and error states
- Modern React with hooks

## GraphQL Queries

The application uses the following GraphQL queries:

- `GET_COURSES`: Fetches all available courses
- `GET_COURSE`: Fetches a single course by ID

## Project Structure

```
src/
├── components/          # React components
│   ├── CourseList.js   # Main course listing component
│   └── CourseList.css  # Styling for course list
├── graphql/            # GraphQL queries and mutations
│   └── queries.js      # Course queries
├── apollo-client.js    # Apollo Client configuration
├── App.js              # Main App component
├── App.css             # App styling
├── index.js            # Entry point
└── index.css           # Global styles
```