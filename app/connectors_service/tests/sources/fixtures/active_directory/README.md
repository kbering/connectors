# Active Directory Test Fixture

Docker Compose setup for testing the Active Directory connector locally.

## Quick Start

### 1. Start Services

```bash
# Set Elasticsearch image
export ELASTICSEARCH_DRA_DOCKER_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:9.2.1

# Start Elasticsearch and Samba AD
cd app/connectors_service/tests/sources/fixtures/active_directory
docker-compose up -d

# Wait for services to be ready (30-60 seconds)
docker-compose ps
```

### 2. Verify Active Directory

```bash
# Check AD is running
docker exec samba-ad samba-tool domain info 127.0.0.1

# List default users
docker exec samba-ad samba-tool user list
```

### 3. Add Test Users (Optional)

```bash
# Add test user
docker exec samba-ad samba-tool user create testuser TestPass123! \
  --given-name="Test" \
  --surname="User" \
  --mail-address="testuser@testlab.local"

# Add test group
docker exec samba-ad samba-tool group add "IT-Team"

# Add user to group
docker exec samba-ad samba-tool group addmembers "IT-Team" testuser
```

## Connection Details

### Active Directory
- **Host**: `localhost`
- **Port**: `389` (LDAP)
- **Username**: `Administrator@TESTLAB.LOCAL`
- **Password**: `Passw0rd123!`
- **Base DN**: `DC=TESTLAB,DC=LOCAL`
- **Domain**: `TESTLAB.LOCAL`

### Elasticsearch
- **URL**: `http://localhost:9200`
- **Username**: `elastic`
- **Password**: `changeme`

## Configure Connector

Create `config.yml`:

```yaml
elasticsearch:
  host: http://localhost:9200
  username: elastic
  password: changeme

connectors:
  - connector_id: active-directory-test
    service_type: active_directory
    configuration:
      host: localhost
      port: 389
      username: "Administrator@TESTLAB.LOCAL"
      password: "Passw0rd123!"
      base_dn: "DC=TESTLAB,DC=LOCAL"
      use_ssl: false
      auth_type: "SIMPLE"
      sync_users: true
      sync_groups: true
      sync_computers: false
      sync_ous: false
```

## Run Connector

```bash
# Install dependencies
make install

# Run connector
bin/elastic-ingest --config-file config.yml
```

## Testing Scenarios

### Test Full Sync

1. Start services
2. Configure connector
3. Run connector
4. Check Elasticsearch for documents:

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
curl -u elastic:changeme "http://localhost:9200/.elastic-connectors/_search?pretty"
```

### Test Incremental Sync (USN)

1. Run initial sync
2. Add/modify users in AD:
   ```bash
   docker exec samba-ad samba-tool user create newuser Pass123!
   ```
3. Run sync again
4. Verify only new/changed objects synced

### Test Different Object Types

```bash
# Add computer
docker exec samba-ad samba-tool computer create TESTPC

# Add OU
docker exec samba-ad samba-tool ou create "OU=TestOU,DC=TESTLAB,DC=LOCAL"
```

## Cleanup

```bash
# Stop services
docker-compose down

# Remove volumes (fresh start)
docker-compose down -v
```

## Troubleshooting

### AD not starting

```bash
# Check logs
docker-compose logs samba-ad

# Common issue: requires privileged mode
# Solution: Ensure Docker has necessary permissions
```

### Connection refused

```bash
# Check AD is listening
docker exec samba-ad netstat -tln | grep 389

# Test LDAP connection
ldapsearch -x -H ldap://localhost:389 -D "Administrator@TESTLAB.LOCAL" \
  -w "Passw0rd123!" -b "DC=TESTLAB,DC=LOCAL"
```

### Elasticsearch not accessible

```bash
# Wait longer - Elasticsearch takes time to start
docker-compose logs elasticsearch

# Test connection
curl http://localhost:9200
```

## Integration Tests

Run automated tests:

```bash
# Set environment for tests
export AD_HOST=localhost
export AD_PORT=389
export AD_USERNAME="Administrator@TESTLAB.LOCAL"
export AD_PASSWORD="Passw0rd123!"
export AD_BASE_DN="DC=TESTLAB,DC=LOCAL"

# Run integration tests
pytest -m integration app/connectors_service/connectors/sources/active_directory/
```
