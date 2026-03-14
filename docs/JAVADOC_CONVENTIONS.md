# Code documentation conventions — Detective RPG

> Goal: document the *why*, not the *what*. The code shows what.

---

## What to document

Always write doc comments for:
- All `public` and `protected` classes and interfaces
- Public methods with non-obvious parameters, return values, or side effects
- Methods that enforce business rules (see module docs for `BR-*` references)
- Custom repository methods with non-trivial queries
- Exception classes — document *when* they are thrown
- Configuration classes — document *what* they configure
- Non-obvious constants and enum values (e.g. role types, status transitions)

## What to skip

Do NOT write doc comments for:
- Simple getters and setters
- `@Override` implementations that exactly follow the interface contract
- Private helpers that are clear from context (use inline `//` comments instead)
- Test methods — use descriptive method names instead
- Auto-generated code (Lombok, MapStruct output)

---

## Decision rule

Ask three questions before writing a comment:
1. Would a developer need to look elsewhere to understand this? → write it
2. Is there a non-obvious constraint, side effect, or game rule? → write it
3. Does the name + types already tell the full story? → skip it

---

## Templates by class type

### Service class

```java
/**
 * Manages {what it manages — e.g. "crime case lifecycle and evidence collection"}.
 *
 * <p>{Key constraint or invariant — e.g. "A case can only receive new evidence
 * while its status is OPEN. Attempts to add evidence to a CLOSED case throw
 * {@link CaseClosedException}."}
 *
 * @see {RelatedClass}
 */
@Service
@RequiredArgsConstructor
public class {Name}Service {
```

### Service method — simple

```java
/**
 * Returns the {@link Case} with the given ID, asserting it is assigned to the requesting detective.
 *
 * @param id         the case ID
 * @param detectiveId the ID of the detective making the request
 * @return the case
 * @throws CaseNotFoundException      if no case exists with this ID
 * @throws UnauthorisedAccessException if the case is not assigned to this detective
 */
public Case getById(Long id, Long detectiveId) {
```

### Service method — complex

```java
/**
 * Submits a verdict for the given case, resolves all player win conditions, and triggers scoring.
 *
 * <p>This method:
 * <ol>
 *   <li>Validates the case is still in OPEN status</li>
 *   <li>Records the accusation against the named suspect</li>
 *   <li>Compares the accusation to the actual killer (held server-side)</li>
 *   <li>Closes the case and broadcasts the result to all players</li>
 *   <li>Triggers a scoring event in the Time &amp; Points Service</li>
 * </ol>
 *
 * <p><strong>Side effect:</strong> Calls Time &amp; Points Service to finalise scores.
 * This call is synchronous — if the service is unavailable, the verdict fails.
 *
 * <p><strong>Idempotency:</strong> Not idempotent. Submitting a verdict twice throws
 * {@link CaseAlreadyClosedException}.
 *
 * @param caseId    the case to close
 * @param suspectId the suspect being accused
 * @return the verdict result including whether the accusation was correct
 * @throws CaseNotFoundException      if the case does not exist
 * @throws CaseAlreadyClosedException if the case is already closed
 */
public VerdictResult submitVerdict(Long caseId, Long suspectId) {
```

### Repository — custom query

```java
/**
 * Returns all open cases assigned to the given detective, ordered by creation time descending.
 *
 * <p>Results are ordered by {@code created_at} descending (most recent first).
 *
 * <p><strong>Performance note:</strong> Filtered by {@code detective_id} index on
 * {@code cases} table. Returns an empty list if no cases are assigned, never {@code null}.
 *
 * @param detectiveId the detective's player ID
 * @return list of open cases, may be empty, never {@code null}
 */
@Query("SELECT c FROM Case c WHERE c.detectiveId = :detectiveId AND c.status = 'OPEN' ORDER BY c.createdAt DESC")
List<Case> findOpenCasesByDetective(@Param("detectiveId") Long detectiveId);
```

### Entity

```java
/**
 * Represents a crime case under investigation.
 *
 * <p>Lifecycle: {@code OPEN} → {@code CLOSED} (terminal).
 * A case transitions to {@code CLOSED} when a verdict is submitted via
 * {@link CaseService#submitVerdict}. There is no way to reopen a closed case.
 *
 * <p>The {@code killerPlayerId} field is set at case creation time and is
 * never exposed through the API — it is used only for verdict resolution.
 */
@Entity
@Table(name = "cases")
public class Case {

    /**
     * The player ID of the actual killer.
     * {@code null} until the game master assigns a killer role.
     * Never included in API responses.
     */
    @Column(name = "killer_player_id")
    private Long killerPlayerId;
```

### Exception class

```java
/**
 * Thrown when a detective attempts to perform an action on a case they are not assigned to.
 *
 * <p>Maps to HTTP {@code 403 Forbidden} via
 * {@link com.detectiverpg.shared.exception.GlobalExceptionHandler}.
 */
public class UnauthorisedAccessException extends RuntimeException {
```

### Configuration class

```java
/**
 * Configures the Redis connection used for real-time game clock and rate limiting.
 *
 * <p>Reads connection details from environment variables {@code REDIS_HOST} and
 * {@code REDIS_PORT} (default: 6379).
 *
 * <p>The configured {@link RedisTemplate} is shared — do not create additional instances.
 *
 * @see TimeTrackingService
 */
@Configuration
public class RedisConfig {
```

---

## Inline comment conventions

Use `//` inside method bodies to explain *why* non-obvious choices were made.

**Good:**
```java
// Peak hours add 15 min to all travel — see BR-MAP-001
int travelMinutes = base + (isPeakHour ? 15 : 0);

// Capture detective ID before async thread loses the security context —
// Spring Security clears the context after request completion.
Long detectiveId = SecurityContextHolder.getContext()...;
```

**Bad — explains what, not why:**
```java
// Get the case by ID    ← the code shows this; delete it
Case c = caseRepository.findById(id);
```

**TODO / FIXME convention:**
```java
// TODO(DRPG-42): Replace synchronous scoring call with async event
// FIXME: Travel time ignores PostGIS actual road distance — DRPG-88
// HACK: Hard-coded peak hour windows — revert before v1 release (DRPG-101)
```

Always include a ticket reference. Bare `// TODO` with no context is noise.

---

## Business rule references

When a method enforces a documented business rule, reference it:

```java
// BR-CASE-002: A verdict against an innocent suspect deducts 100 points
if (!accusedIsKiller) {
    pointsService.deduct(detectiveId, WRONG_ACCUSATION_PENALTY);
}
```

Business rules are documented in the relevant module doc under `docs/modules/`. Until modules are implemented, refer to the spec in `docs/specs/`.

---

## Anti-patterns

1. **Restating the code** — `// Sets status to ACTIVE` on a line that sets status to ACTIVE.
2. **Empty tags** — `@param id` with no description.
3. **Documenting implementation details** — `// Uses SELECT * FROM cases WHERE...` — document behaviour, not SQL.
4. **Outdated comments** — treat comments as code; update them in the same commit that changes the behaviour.

**PR checklist for changed public methods:**
- [ ] Does the doc comment still accurately describe the contract?
- [ ] Are all `@throws` tags still accurate?
- [ ] If a business rule changed, is `BR-MODULE-NNN` updated in the module doc?
