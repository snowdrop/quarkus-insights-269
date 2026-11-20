package com.todo.app.controller;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

// Replaces Spring Boot's BasicErrorController convention, which rendered
// templates/error.html for any unhandled error (404, 500, ...).
public class ErrorPageMapper {

    private static final Logger LOG = Logger.getLogger(ErrorPageMapper.class);

    @ServerExceptionMapper
    public Response mapWebApplicationException(WebApplicationException e) {
        return errorPage(e.getResponse().getStatus());
    }

    @ServerExceptionMapper
    public Response mapException(Exception e) {
        LOG.error("Unhandled exception", e);
        return errorPage(Response.Status.INTERNAL_SERVER_ERROR.getStatusCode());
    }

    private static Response errorPage(int status) {
        return Response.status(status)
                .type(MediaType.TEXT_HTML)
                .entity(TaskResource.Templates.error().render())
                .build();
    }
}
