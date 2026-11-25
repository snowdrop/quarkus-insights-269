# Awesome To-Do App -> Quarkus Migration Summary

**Migration Date**: 2026-11-20
**Source**: Spring Boot 3.5.3 (Java 21)
**Target**: Quarkus 3.40.1.2 (Java 17)
**Strategy**: full-quarkus
**Overall Status**: ✅ **100% Complete** (Backend: 100%, Frontend: 100%)

## 1. Executive Summary

The Spring Boot to-do app (Spring MVC + Thymeleaf + Spring Data JPA + MySQL) now runs on Quarkus REST, Qute and Hibernate ORM with Panache. Every applicable module finished. Messaging was skipped because the app doesn't use it. All 6 verification checks pass. Nothing was left as a `TODO: Migration required`.

**Key Achievements**
- Spring Boot parent, starters and plugin replaced with the Quarkus BOM and extensions
- `TaskRepository` (Spring Data) replaced with Panache active-record methods on `Task`
- `TaskService` interface and `TaskServiceImpl` merged into one `@ApplicationScoped` bean with `jakarta.transaction.Transactional`
- `@Controller` became a JAX-RS `TaskResource` that uses type-safe Qute templates (`@CheckedTemplate`)
- Spring Boot's automatic `error.html` handling is reproduced with `@ServerExceptionMapper`
- Dev and test runs use Dev Services MySQL, so no local database is needed

**Remaining Work**
- Point the `%prod` datasource at the real MySQL instance and smoke-test against the existing schema (sequence table and column names)
- Decide whether to keep the unused `jjwt` 0.9.1 dependency

## 2. Migration Modules

| Module | Name | Status | Details |
|--------|------|--------|---------|
| 0 | prerequisite | Complete | JDK 25 (GraalVM CE), Maven 3.9.4 wrapper, Podman 6.0.2 |
| 1 | planning | Complete | Non-interactive; `migration-spec.yaml` written |
| 2 | build | Complete | pom.xml rewritten; application.properties migrated |
| 3 | persistence | Complete | Entity changed to Panache; repository removed; mtools persistence 8/8 PASS |
| 4 | code | Complete | Controller changed to JAX-RS resource; service merged; main class removed |
| 5 | messaging | Skipped | No messaging detected |
| 6 | frontend | Complete | Thymeleaf converted to Qute; static assets moved; CSRF JS removed |
| 7 | testing | Complete | `@SpringBootTest` replaced with `@QuarkusTest`; 2 REST Assured tests added |
| 8 | cleanup | Complete | No Spring imports or dependencies left; README updated |

## 3. Component Migration Status

### JPA Entities (1/1 - 100%)
| Entity | Table | Status | Notes |
|---|---|---|---|
| Task | tasks | ✅ | Extends `PanacheEntityBase`; explicit `@Id @GeneratedValue(AUTO)` kept; public fields |

**Migration Pattern**: The JPA entity now extends `PanacheEntityBase` with public fields. The id mapping is kept so the schema stays the same.

### Repositories (1/1 - 100%)
| Repository | Entity | Status | Notes |
|---|---|---|---|
| TaskRepository | Task | ✅ Removed | Replaced by active-record static methods (`Task.listAll()`, `Task.deleteById()`, `Task.findAll().page()`) |

**Migration Pattern**: The Spring Data `JpaRepository` is replaced by the Panache active record.

### Services (1/1 - 100%)
| Service | Status | Notes |
|---|---|---|
| TaskService (+ TaskServiceImpl) | ✅ | Single `@ApplicationScoped` class; writes are `@Transactional`; `Page<Task>` becomes `PanacheQuery<Task>` |

**Migration Pattern**: The interface and its implementation are merged into one CDI bean.

### Controllers (1/1 - 100%)
| Controller | Endpoints | Status | Notes |
|---|---|---|---|
| TaskController → TaskResource | `GET /`, `GET /error`, `GET /home`, `GET /home/{pageNo}`, `POST /home`, `DELETE /home/{taskId}` | ✅ | `redirect:` becomes `Response.seeOther` (303) |
| (new) ErrorPageMapper | n/a | ✅ | Replaces Spring Boot's BasicErrorController and its `error.html` convention |

**Migration Pattern**: Spring MVC `@Controller` + `Model` becomes JAX-RS + Qute `@CheckedTemplate`.

### Templates
- `templates/home.html` → `templates/TaskResource/home.html`
- `templates/error.html` → `templates/TaskResource/error.html`
- `static/js/home.js` → `META-INF/resources/js/home.js` (CSRF header code removed)
- `static/favicon.ico` → `META-INF/resources/favicon.ico`

### Configuration
| Configuration | Status | Notes |
|---|---|---|
| server.port | ✅ | `quarkus.http.port=8081` (+ `quarkus.http.test-port=0`) |
| spring.datasource.* | ✅ | `quarkus.datasource.db-kind=mysql` + `%prod.` URL/user/password |
| spring.jpa.* | ✅ | `schema-management.strategy=update`, `log.sql=true`, dialect auto-detected |
| Naming strategy | ✅ | `CamelCaseToUnderscoresNamingStrategy` keeps Spring's `due_date` column |

## 4. Technology Mapping

**Framework**
- Spring Boot 3.5.3 → Quarkus 3.40.1.2

**Persistence**
- Spring Data JPA → Hibernate ORM with Panache (active record)
- mysql-connector-j → quarkus-jdbc-mysql

**Web Layer**
- Spring MVC `@Controller` → Quarkus REST (JAX-RS) + quarkus-rest-jackson
- Thymeleaf → Qute (quarkus-rest-qute)

**Dependency Injection**
- `@Service` / `@Autowired` → `@ApplicationScoped` / `@Inject`

**Configuration**
- `spring.*` / `server.*` → `quarkus.*` with a `%prod` profile for the datasource

## 5. Build & Deployment

- `./mvnw clean compile -DskipTests` ✅
- `./mvnw clean package -DskipTests` ✅ → `target/quarkus-app/quarkus-run.jar`
- `./mvnw test` ✅ 3/3
- Dev mode: `./mvnw quarkus:dev` (Dev Services starts MySQL; with Podman on macOS, export `DOCKER_HOST` to the Podman socket)
- Production: `java -jar target/quarkus-app/quarkus-run.jar`
- Native: `./mvnw package -Dnative`
- `Dockerfile` (MySQL 8.0 image) is unchanged

## 6. Database

MySQL 8 database `todo`, table `tasks` (`id`, `title`, `description`, `due_date`).

```properties
quarkus.datasource.db-kind=mysql
%prod.quarkus.datasource.jdbc.url=jdbc:mysql://127.0.0.1:3306/todo
%prod.quarkus.datasource.username=root
%prod.quarkus.datasource.password=root
quarkus.hibernate-orm.schema-management.strategy=update
quarkus.hibernate-orm.log.sql=true
quarkus.hibernate-orm.physical-naming-strategy=org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy
```

## 7. Migration Reports

1. `migration-reports/validation-report.json` — mtools project-setup 10/11 (the missing `src/test/resources` was then created), persistence 8/8
2. `migration-reports/reporting-report.json` — reporting module output

No compile-fix report: every compile succeeded on the first attempt.

## 8. Next Steps

**Immediate**
1. Run against the existing production MySQL and confirm the id sequence table and columns match.

**Short Term**
1. Remove `jjwt` 0.9.1 if it really is unused. It is old and pulls in an outdated API.
2. Return JSON (not HTML) error responses for the AJAX endpoints if API clients need them.

**Long Term**
1. Consider `quarkus-rest-csrf` if CSRF protection is wanted. The original app didn't enable Spring Security.
2. Consider Flyway instead of `schema-management.strategy=update`.

## 9. Key Migration Patterns

```java
// BEFORE
@Entity @Table(name = "tasks")
public class Task {
  @Id @GeneratedValue(strategy = GenerationType.AUTO) private Long id;
  @DateTimeFormat(pattern = "yyyy-MM-dd") private LocalDate dueDate; // + getters/setters
}
public interface TaskRepository extends JpaRepository<Task, Long> {}

// AFTER
@Entity @Table(name = "tasks")
public class Task extends PanacheEntityBase {
  @Id @GeneratedValue(strategy = GenerationType.AUTO) public Long id;
  public LocalDate dueDate;
}
// TaskRepository removed: Task.listAll(), Task.deleteById(id), Task.findAll().page(Page.of(i, size))
```

```java
// BEFORE
@GetMapping("/home/{pageNo}")
public String findPaginated(@PathVariable int pageNo, Model model) { ...; return "home"; }

// AFTER
@GET @Path("home/{pageNo}") @Produces(MediaType.TEXT_HTML)
public Response findPaginated(@PathParam("pageNo") int pageNo) {
  ...; return Response.ok(Templates.home(new Task(), tasks, false, pageNo, totalPages, count)).build();
}
```

## 10. Lessons Learned

**What Went Well**
1. The app is small and has no security or messaging, so every pattern mapped cleanly.
2. Dev Services removed the need for a local MySQL during tests.

**Challenges**
1. The build module can't compile on its own: removing Spring dependencies breaks the Java code until the code module has run.
2. Thymeleaf's `#temporals.format` and Qute's `format()` both use the locale for month names. A new test assertion failed because this JVM's locale is Spanish, so it was made locale-independent.
3. Spring Boot renders `templates/error.html` for every error by convention. That needed an explicit `@ServerExceptionMapper`.

## 11. Resources

- https://quarkus.io/guides/
- https://quarkus.io/guides/rest
- https://quarkus.io/guides/qute-reference
- https://quarkus.io/guides/hibernate-orm-panache
- https://quarkus.io/guides/datasource
- https://quarkus.io/guides/databases-dev-services
- https://quarkus.io/guides/smallrye-health

## 12. Conclusion

The migration is complete and verified. The app builds, all tests pass, it starts in dev mode with a healthy database check, and a manual smoke test of every endpoint behaved like the Spring version. Before going to production, confirm it against the real MySQL schema.

---
**Generated by**: Claude Code (claude-opus-5-5)
**Date**: 2026-11-20
**Version**: 1.0
**Token usage**: not available in session (~$n/a estimated)
