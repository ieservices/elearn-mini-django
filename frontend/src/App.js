import React from 'react';
import { ApolloProvider } from '@apollo/client';
import client from './apollo-client';
import CourseList from './components/CourseList';
import './App.css';

function App() {
  return (
    <ApolloProvider client={client}>
      <div className="App">
        <header className="app-header">
          <h1>ieServices E-Learning Platform</h1>
          <p>Your gateway to knowledge and professional growth</p>
        </header>
        <main className="app-main">
          <CourseList />
        </main>
        <footer className="app-footer">
          <p>&copy; 2025 ieServices. All rights reserved.</p>
        </footer>
      </div>
    </ApolloProvider>
  );
}

export default App;