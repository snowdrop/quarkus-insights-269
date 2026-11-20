package com.todo.app.controller;

import java.net.URI;
import java.util.List;

import com.todo.app.entity.Task;
import com.todo.app.service.TaskService;

import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.qute.CheckedTemplate;
import io.quarkus.qute.TemplateInstance;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/")
public class TaskResource {

    @Inject
    TaskService taskService;

    @CheckedTemplate
    public static class Templates {
        public static native TemplateInstance error();

        public static native TemplateInstance home(Task task, List<Task> tasks, boolean noTasks,
                int currentPage, int totalPages, long totalItems);
    }

    @GET
    @Path("error")
    @Produces(MediaType.TEXT_HTML)
    public TemplateInstance viewErrorPage() {
        return Templates.error();
    }

    @GET
    public Response viewIndexPage() {
        return Response.seeOther(URI.create("/home")).build();
    }

    @GET
    @Path("home")
    @Produces(MediaType.TEXT_HTML)
    public Response viewHome() {
        return findPaginated(1);
    }

    @GET
    @Path("home/{pageNo}")
    @Produces(MediaType.TEXT_HTML)
    public Response findPaginated(@PathParam("pageNo") int pageNo) {

        // Spring's PageRequest.of() rejected page indexes < 0 before the original
        // "pageNo < 1" check could run; redirect up front instead.
        if (pageNo < 1) {
            return redirect("/home");
        }

        int pageSize = 6;

        PanacheQuery<Task> page = taskService.getAllTasksPage(pageNo, pageSize);
        List<Task> tasks = page.list();

        if (tasks.isEmpty()) {
            if (pageNo > 1) {
                return redirect("/home/" + (pageNo - 1));
            }
            // Qute requires every template parameter, even on the empty path
            return Response.ok(Templates.home(new Task(), List.of(), true, pageNo, 0, 0)).build();
        }

        int totalPages = page.pageCount();
        if (pageNo > totalPages) {
            return redirect("/home/" + totalPages);
        }

        return Response.ok(Templates.home(new Task(), tasks, false, pageNo, totalPages, page.count())).build();
    }

    // Create task using AJAX request
    @POST
    @Path("home")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public List<Task> createTask(Task task) {
        taskService.addTask(task);
        return taskService.getAllTasks();
    }

    // Delete task using AJAX request
    @DELETE
    @Path("home/{taskId}")
    public Response deleteTask(@PathParam("taskId") Long taskId) {
        taskService.deleteTask(taskId);
        return Response.ok().build();
    }

    private static Response redirect(String location) {
        return Response.seeOther(URI.create(location)).build();
    }
}
