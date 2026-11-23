# How-To: Test Scripts in Containers

See [Scripts and CLI Reference](../../03-reference/cli-and-scripts/scripts-and-cli-reference.md) first.

## Preconditions

1. Install Docker and GNU Make on the host.
2. Confirm that the Docker daemon runs.
3. Open a shell at the repository root.

## Safety Instructions

**CAUTION:** Mount the repository as read-only (`:ro`). Do not run database backup or restore scripts against production hosts.

## Procedure

1. Build the Debian container image:

```bash
make -C docker/script_tests build
```

2. Run the full container script test suite:

```bash
make -C docker/script_tests test
```

3. Run a single script test with `SCRIPT`:

```bash
make -C docker/script_tests test-one SCRIPT=clustercheck
```

4. Run the Galera container test suite:

```bash
make -C docker/mariadb up-galera
make -C docker/mariadb test-galera
```

## Verification Check

1. Confirm that the container runner outputs `0 failed`.
2. Run `RUN_DOCKER_SCRIPT_TESTS=1 python -m unittest tests/test_all_scripts_coverage.py -v` and confirm that all tests pass.

## Rollback

1. Remove the test container image:

```bash
make -C docker/script_tests clean
```

2. Stop the Galera lab cluster:

```bash
make -C docker/mariadb down-galera
```

Related: [Parameters and Ports](../../03-reference/configuration/automation-parameters-and-ports.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
