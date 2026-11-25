package com.todo.app.service;

import com.todo.app.entity.Task;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

import java.util.List;

// Interface + TaskServiceImpl merged into a single CDI bean.
// TaskRepository (Spring Data) replaced by Panache active-record methods on Task.
@ApplicationScoped
public class TaskService {

  // Add task
  @Transactional
  public void addTask(Task task) {
    task.persist();
  }

  // Delete task
  @Transactional
  public void deleteTaskById(Long id) {
    Task.deleteById(id);
  }

  // Update task by id
  @Transactional
  public void updateTaskById(Long id, Task task) {
    // Same semantics as Spring Data save(): insert or merge
    Task.getEntityManager().merge(task);
  }

  // Get all tasks
  public List<Task> getAllTasks() {
    return Task.listAll();
  }

  // Delete task by id
  @Transactional
  public void deleteTask(Long taskId) {
    Task.deleteById(taskId);
  }

  // Get task by page (pageNo is 1-based, like the original PageRequest.of(pageNo - 1, ...))
  public PanacheQuery<Task> getAllTasksPage(int pageNo, int pageSize) {
    return Task.<Task>findAll().page(Page.of(pageNo - 1, pageSize));
  }

}
