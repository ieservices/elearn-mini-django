import React, { useState } from 'react';
import { useQuery } from '@apollo/client';
import { GET_COURSES } from '../graphql/queries';
import './CourseList.css';

function CourseList() {
  const { loading, error, data } = useQuery(GET_COURSES);
  const [expandedCourseId, setExpandedCourseId] = useState(null);

  const toggleCourse = (courseId) => {
    setExpandedCourseId(expandedCourseId === courseId ? null : courseId);
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading courses...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <h3>Error loading courses</h3>
        <p>{error.message}</p>
      </div>
    );
  }

  const courses = data?.courses || [];

  if (courses.length === 0) {
    return (
      <div className="empty-state">
        <h3>No courses available</h3>
        <p>Check back later for new courses!</p>
      </div>
    );
  }

  return (
    <div className="course-list">
      <h2>Available Courses</h2>
      <div className="courses-grid">
        {courses.map((course) => (
          <div
            key={course.id}
            className={`course-card ${expandedCourseId === course.id ? 'expanded' : ''}`}
            onClick={() => toggleCourse(course.id)}
            role="button"
            tabIndex={0}
            onKeyPress={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                toggleCourse(course.id);
              }
            }}
          >
            <div className="course-header">
              <h3>{course.title}</h3>
              <span className={`status-badge ${course.isActive ? 'active' : 'inactive'}`}>
                {course.isActive ? 'Active' : 'Inactive'}
              </span>
            </div>
            {expandedCourseId === course.id && course.description && (
              <div className="course-description">
                <p>{course.description}</p>
              </div>
            )}
            <div className="course-footer">
              <p className="course-date">
                Created: {new Date(course.createdAt).toLocaleDateString('de-DE', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default CourseList;