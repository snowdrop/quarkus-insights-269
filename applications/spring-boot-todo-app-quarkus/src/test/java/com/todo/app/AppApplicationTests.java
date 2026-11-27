package com.todo.app;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;

import org.junit.jupiter.api.Test;

import io.quarkus.test.junit.QuarkusTest;

@QuarkusTest
class AppApplicationTests {

	@Test
	void contextLoads() {
	}

	@Test
	void homePageRenders() {
		given()
			.when().get("/home")
			.then()
				.statusCode(200)
				.body(containsString("Awesome To-Do App"));
	}

	@Test
	void createAndDeleteTask() {
		Long id = given()
			.contentType("application/json")
			.body("{\"title\":\"Test\",\"description\":\"Desc\",\"dueDate\":\"2026-12-01\"}")
			.when().post("/home")
			.then()
				.statusCode(200)
				.body("title", org.hamcrest.Matchers.hasItem("Test"))
				.extract().jsonPath().getLong("find { it.title == 'Test' }.id");

		given()
			.when().get("/home")
			.then()
				.statusCode(200)
				// month name follows the JVM default locale, as with Thymeleaf
				.body(org.hamcrest.Matchers.matchesRegex("(?s).*01 \\S+ 2026.*"));

		given()
			.when().delete("/home/" + id)
			.then()
				.statusCode(200);
	}

}
