package com.todo.app.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;

import java.time.LocalDate;

@Entity
@Table(name = "tasks")
public class Task extends PanacheEntityBase {

  // Explicit id kept (instead of PanacheEntity's) to preserve the original
  // GenerationType.AUTO mapping and the existing database schema.
  @Id
  @GeneratedValue(strategy = GenerationType.AUTO)
  public Long id;

  public String title;

  public String description;

  // REMOVED: @org.springframework.format.annotation.DateTimeFormat(pattern = "yyyy-MM-dd")
  // It only drove Spring MVC form binding. The AJAX endpoint receives JSON, and Jackson
  // (quarkus-rest-jackson) parses LocalDate as ISO-8601 (yyyy-MM-dd) by default.
  public LocalDate dueDate;

  public Task() {
  }

  public Task(Long id, String title, String description, LocalDate dueDate) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.dueDate = dueDate;
  }
}
