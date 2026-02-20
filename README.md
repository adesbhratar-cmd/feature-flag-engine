# Feature Flag Engine

Production-grade Rails API for managing feature flags with user, group, and region-based overrides. Supports runtime evaluation with configurable precedence and in-memory caching.

## Quick Start

```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

API available at `http://localhost:3000/api/v1`

## Architecture

**Design:** Clean Architecture with Service Objects, Strategy Pattern for extensible evaluation

**Structure:**
```
app/
├── controllers/api/v1/     # HTTP layer (thin)
├── models/                  # Data models with validations
├── services/feature_flags/  # Business logic (Evaluator, RuleEngine, CRUD services)
└── errors/                  # Custom error classes
```

**Key Design Decisions:**
- **Strategy Pattern**: RuleEngine with individual rule classes (UserOverrideRule, GroupOverrideRule, RegionOverrideRule, GlobalDefaultRule) for extensibility
- **Service Objects**: All business logic in services; controllers handle only request/response
- **Evaluation Precedence**: User > Group > Region > Global Default
- **Caching**: In-memory store (Phase 2 requirement), 5-minute TTL, auto-invalidation on changes

## API Endpoints

### Feature Flags

```bash
# List all
GET /api/v1/feature_flags

# Get one
GET /api/v1/feature_flags/:id

# Create
POST /api/v1/feature_flags
Body: { "feature_flag": { "name": "feature_name", "global_default_state": false, "description": "..." } }

# Update
PATCH /api/v1/feature_flags/:id
Body: { "feature_flag": { "global_default_state": true } }

# Delete
DELETE /api/v1/feature_flags/:id

# Evaluate
POST /api/v1/feature_flags/:id/evaluate
Body: { "user_id": "user123", "group_id": "premium", "region": "us-east" }
Query: ?metadata=true (returns source of evaluation)

# Get overrides
GET /api/v1/feature_flags/:id/overrides
```

### Overrides

```bash
# Create/Update override
POST /api/v1/feature_flags/:feature_flag_id/overrides
Body: { "type": "user|group|region", "identifier": "id", "enabled": true }

# Remove override
DELETE /api/v1/feature_flags/:feature_flag_id/overrides
Body: { "type": "user|group|region", "identifier": "id" }
```

**Example Response:**
```json
{
  "enabled": true,
  "feature_flag_name": "new_feature",
  "source": "user"  // when metadata=true
}
```

**Error Format:**
```json
{
  "error": {
    "type": "validation_error",
    "message": "Name can't be blank",
    "details": ["Name can't be blank"]
  }
}
```

**Error Handling Architecture:**
- **Custom Errors** (`ApplicationError` subclasses): Use `to_json` method for consistent formatting
  - `ValidationError`: Service validation failures
  - `FeatureFlagError`: Feature flag specific errors
  - `FeatureFlagNotFoundError`: 404 errors
- **Rails Exceptions**: Handled with helper method for consistent JSON structure
  - `ActiveRecord::RecordNotFound`: 404 errors
  - `ActiveRecord::RecordInvalid`: Model validation failures
  - `ArgumentError`: Invalid parameters
- All errors return consistent JSON structure with `type`, `message`, and optional `details`

## Testing

```bash
bundle exec rspec              # Run all tests
COVERAGE=true bundle exec rspec # With coverage report
```

**Coverage:** 90%+ (SimpleCov)  
**Test Types:** Model specs (validations, associations), Service specs (business logic), Request specs (API endpoints)

## Caching

- **Store:** Rails.cache with memory_store (Phase 2 requirement, NOT Redis)
- **TTL:** 5 minutes
- **Key Format:** `feature_flag_evaluation:{id}:{user_id}:{group_id}:{region}`
- **Invalidation:** Automatic on override create/update/delete and flag updates

## Assumptions & Tradeoffs

**Assumptions:**
- User/Group IDs are string identifiers (not DB foreign keys)
- Regions are simple strings (e.g., "us-east")
- Binary states only (enabled/disabled)
- Single tenant, API-only (no UI)

**Tradeoffs:**
- Memory cache vs Redis: Chose memory per requirements; Redis better for scale
- Service Objects vs Interactors: Plain POROs for simplicity
- Strategy Pattern: Added for extensibility; could be simpler for current needs
- Cache TTL: 5 minutes balances freshness vs performance

**Known Limitations:**
- No pagination on list endpoints
- No rate limiting (add for production)
- Case normalization to lowercase (may not suit all use cases)
- Single region per request

## What's Next

**With more time:**
- Percentage rollouts, attribute-based rules, A/B testing
- Redis cache, batch evaluation, GraphQL API
- Admin UI, CLI tool, SDK libraries
- Monitoring, analytics, audit logging

## Run It

```bash
# Setup
bundle install
bin/rails db:create db:migrate

# Start
bin/rails server

# Test
curl http://localhost:3000/api/v1/feature_flags
bundle exec rspec
```

---

**Stack:** Rails 8.0, PostgreSQL, RSpec | **Architecture:** Clean Architecture, SOLID, Service Objects, Strategy Pattern | **Coverage:** 90%+
