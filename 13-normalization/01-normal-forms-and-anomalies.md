# 01. Normal Forms, Functional Dependencies, and Relational Anomalies

## 1. Problem: The Un-Normalized Nightmare

Consider a single flat table storing student course registrations:

```
student_courses_unnormalized:
┌────────────┬──────────────┬─────────────┬─────────────┬──────────────┬──────────────┐
│ student_id │ student_name │ course_code │ course_name │ instructor   │ inst_office  │
├────────────┼──────────────┼─────────────┼─────────────┼──────────────┼──────────────┤
│ 101        │ Alice Chen   │ CS101       │ Intro to CS │ Dr. Turing   │ Room 404     │
│ 101        │ Alice Chen   │ CS201       │ Algorithms  │ Dr. Knuth    │ Room 502     │
│ 102        │ Bob Kapoor   │ CS101       │ Intro to CS │ Dr. Turing   │ Room 404     │
└────────────┴──────────────┴─────────────┴─────────────┴──────────────┴──────────────┘
```

This table suffers from three severe relational anomalies:
1. **Update Anomaly**: If Dr. Turing moves from Room 404 to Room 301, we must update multiple rows. If one update fails, data becomes contradictory.
2. **Insertion Anomaly**: We cannot create a new course (e.g. `CS301`) until at least one student enrolls, because `student_id` is part of the identity.
3. **Deletion Anomaly**: If Alice Chen is the only student in `CS201` and drops the course, deleting that row completely erases the record that `CS201` is taught by Dr. Knuth.

---

## 2. Functional Dependencies (FD)

A functional dependency $X \to Y$ states that the value of column set $X$ uniquely determines the value of column set $Y$.
- $\text{student\_id} \to \text{student\_name}$
- $\text{course\_code} \to \text{course\_name}, \text{instructor}$
- $\text{instructor} \to \text{inst\_office}$

---

## 3. The Normalization Staircase

```
                 ┌─────────────────────────────────────────────────────────────┐
                 │                        BCNF                                 │
                 │ Every determinant is a candidate key                        │
                 └──────────────────────────────┬──────────────────────────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 │                        3NF                                  │
                 │ No transitive dependencies (no non-key → non-key FD)        │
                 └──────────────────────────────┬──────────────────────────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 │                        2NF                                  │
                 │ No partial dependencies (all non-key depend on full PK)     │
                 └──────────────────────────────┬──────────────────────────────┘
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 │                        1NF                                  │
                 │ All attribute values are atomic; primary key defined        │
                 └─────────────────────────────────────────────────────────────┘
```

### 3.1 First Normal Form (1NF)
- **Rule**: Each column contains atomic (indivisible) values. No repeating groups or arrays/comma-separated strings in columns.
- **Violation**: `courses_enrolled = 'CS101, CS201, CS301'` in a single cell.

### 3.2 Second Normal Form (2NF)
- **Rule**: Must be in 1NF AND have **no partial key dependencies** (every non-key attribute must depend on the *entire* candidate key, not just a subset).
- **Violation in Composite PK `(student_id, course_code)`**:
  - `student_name` depends only on `student_id` (partial dependency).
  - `course_name` depends only on `course_code` (partial dependency).
- **Fix**: Decompose into `students`, `courses`, and `enrollments`.

### 3.3 Third Normal Form (3NF)
- **Rule**: Must be in 2NF AND have **no transitive dependencies** ($X \to Y \to Z$, where $X$ is candidate key and $Y, Z$ are non-key attributes).
- **Violation in `courses(course_code, course_name, instructor, inst_office)`**:
  - $\text{course\_code} \to \text{instructor} \to \text{inst\_office}$
  - `inst_office` depends on `instructor`, not directly on `course_code`.
- **Fix**: Move instructor details into an `instructors` table.

### 3.4 Boyce-Codd Normal Form (BCNF)
- **Rule**: A stricter version of 3NF. For every non-trivial functional dependency $X \to Y$, $X$ must be a **superkey**.
- Resolves anomalies when a table has multiple overlapping composite candidate keys.

---

## 4. Decomposed 3NF Schema

```sql
CREATE TABLE instructors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    office VARCHAR(50) NOT NULL
);

CREATE TABLE courses (
    code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    instructor_id BIGINT NOT NULL REFERENCES instructors (id)
);

CREATE TABLE students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE enrollments (
    student_id BIGINT NOT NULL REFERENCES students (id),
    course_code VARCHAR(20) NOT NULL REFERENCES courses (code),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, course_code)
);
```
*Zero update anomalies, zero insertion anomalies, zero deletion anomalies.*
