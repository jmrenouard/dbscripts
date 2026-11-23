#!/usr/bin/env bash
# Container test runner for all shell, Python, and Perl scripts under scripts/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SCRIPT_FILTER="${SCRIPT_FILTER:-}"
REQ_FILTER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --filter) SCRIPT_FILTER="${2:-}"; shift 2 ;;
    --require-filter) REQ_FILTER=1; SCRIPT_FILTER="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--filter <substr>] [--require-filter <substr>]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
[ "${REQ_FILTER}" -eq 1 ] && [ -z "${SCRIPT_FILTER}" ] && { echo "Usage: make test-one SCRIPT=<name>" >&2; exit 2; }

SANDBOX="$(mktemp -d)"
export PYTHONPYCACHEPREFIX="${SANDBOX}/pycache"
trap 'rm -rf "${SANDBOX}"' EXIT

# Isolated /tmp stubs for external Perl/Python dependencies and Win32 DPAPI
mkdir -p "${SANDBOX}/py_stubs/mysql" "${SANDBOX}/perl_inc/Nagios/DBD/MySQL"
printf 'package Nagios::DBD::MySQL::Server; 1;\n' > "${SANDBOX}/perl_inc/Nagios/DBD/MySQL/Server.pm"
printf 'package Nagios::DBD::MySQL::Cluster; 1;\n' > "${SANDBOX}/perl_inc/Nagios/DBD/MySQL/Cluster.pm"
printf 'class _C:\n def __enter__(s): return s\n def __exit__(s,*a): pass\ndef connect(*a,**k): return _C()\n' > "${SANDBOX}/py_stubs/mysql/connector.py"
printf 'from . import connector\n' > "${SANDBOX}/py_stubs/mysql/__init__.py"
printf 'def Fire(obj=None): return obj\n' > "${SANDBOX}/py_stubs/fire.py"
printf 'def CryptUnprotectData(d,*a): return (b"stub", d)\n' > "${SANDBOX}/py_stubs/win32crypt.py"

TOTAL=0 PASSED=0 FAILED=0
matches() { [ -z "${SCRIPT_FILTER}" ] || [[ "$1" == *"${SCRIPT_FILTER}"* ]]; }
_gz() { python3 -c 'import gzip,sys; gzip.open(sys.argv[1],"wt").write(sys.argv[2])' "$1" "$2"; }
_mkshim() { mkdir -p "$(dirname "$1")"; printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1"; chmod +x "$1"; }

run_rc() {
  local exp="$1" lbl="$2"; shift 2
  local out="" rc=0
  set +e; out="$("$@" 2>&1)"; rc=$?; set -e
  TOTAL=$((TOTAL + 1))
  if [ "${rc}" -eq "${exp}" ]; then
    PASSED=$((PASSED + 1)); printf '[PASS] %s\n' "${lbl}"
  else
    FAILED=$((FAILED + 1)); printf '[FAIL] %s: rc=%s (exp %s) %s\n' "${lbl}" "${rc}" "${exp}" "${out//$'\n'/ | }" >&2
  fi
}

check_sh() {
  local rel="$1" full="${REPO_ROOT}/$1"
  if [ ! -s "${full}" ] || grep -q $'\r' "${full}"; then
    TOTAL=$((TOTAL + 1)); FAILED=$((FAILED + 1))
    printf '[FAIL] %s: empty or CRLF\n' "${rel}" >&2; return
  fi
  run_rc 0 "${rel} (bash -n)" bash -n "${full}"
}

_smoke_py() {
  local f="$1" b; b="$(basename "$1")"
  case "${b}" in
    mygenconf_mysql.py) python3 "$f" --help >/dev/null && python3 "$f" --port 3307 | grep -q "3307" ;;
    mygenconf_mariadb.py) python3 "$f" port=3307 | grep -q "3307" ;;
    genere_csv.py) python3 "$f" --help >/dev/null && python3 "$f" --filename "${SANDBOX}/g.csv" --rows 3 --days 5 >/dev/null && [ -s "${SANDBOX}/g.csv" ] ;;
    generate_sql_fromcsv.py)
      python3 "$f" --help >/dev/null
      _gz "${SANDBOX}/in.csv.gz" $'source;gen_ts\ns1;2026-01-01\n'
      python3 "$f" --input_file "${SANDBOX}/in.csv.gz" --output_file "${SANDBOX}/out.sql" >/dev/null
      grep -q "DELETE FROM" "${SANDBOX}/out_batch_1.sql" ;;
    mysqldump_database_splitter.py)
      python3 "$f" --help >/dev/null
      _gz "${SANDBOX}/db.sql.gz" $'-- Current Database: `appdb`\nCREATE TABLE t(id INT);\n-- Dump completed on 2026-01-01\n'
      python3 "$f" "${SANDBOX}/db.sql.gz" >/dev/null && [ -s "${SANDBOX}/db.sql.gz_split/appdb.sql.gz" ] ;;
    mysqldump_table_splitter.py)
      python3 "$f" --help >/dev/null
      printf -- "-- Table structure for table \`t1\`\nCREATE TABLE t1(id INT);\n" > "${SANDBOX}/tbl.sql"
      python3 "$f" "${SANDBOX}/tbl.sql" >/dev/null && [ -s "${SANDBOX}/tbl.sql_split/t1_structure.sql.gz" ] ;;
    findip.py)
      mkdir -p "${SANDBOX}/fip" && printf "localhost\n" > "${SANDBOX}/fip/hosts.txt"
      (cd "${SANDBOX}/fip" && python3 "$f" hosts.txt >/dev/null)
      grep -q "^localhost" "${SANDBOX}/fip/hosts_result.csv" ;;
    check_tcp.py)
      python3 -c 'import socket,subprocess,sys,threading; s=socket.socket(); s.bind(("127.0.0.1",0)); s.listen(1); p=s.getsockname()[1]; threading.Thread(target=lambda:s.accept()[0].close(),daemon=True).start(); r=subprocess.run([sys.executable,sys.argv[1],"127.0.0.1",str(p)],capture_output=True,text=True); s.close(); assert r.returncode==0 and "is UP" in r.stdout, r.stdout+r.stderr' "$f" ;;
    extract_schemas.py) PYTHONPATH="${SANDBOX}/py_stubs" python3 "$f" --help ;;
    decryptWorkbenchPasswords.py)
      mkdir -p "${SANDBOX}/wb" && printf "cipher" > "${SANDBOX}/wb/.\\workbench_user_data.dat"
      (cd "${SANDBOX}/wb" && PYTHONPATH="${SANDBOX}/py_stubs" python3 "$f" | grep -q "stub") ;;
    generate_rundeck_doc.py)
      python3 "$f" --help >/dev/null
      mkdir -p "${SANDBOX}/rd_in" "${SANDBOX}/rd_out"
      printf -- "- name: Backup Job\n  description: Nightly backup\n" > "${SANDBOX}/rd_in/job.yaml"
      python3 "$f" --input-dir "${SANDBOX}/rd_in" --output-dir "${SANDBOX}/rd_out" >/dev/null
      [ -s "${SANDBOX}/rd_out/README.md" ] ;;
    generate_doc_description.py)
      mkdir -p "${SANDBOX}/docs_in" && printf "# Title\n\nBody\n" > "${SANDBOX}/docs_in/s.md"
      python3 "$f" --docs-dir "${SANDBOX}/docs_in" --output-file INDEX.md >/dev/null
      [ -s "${SANDBOX}/docs_in/INDEX.md" ] ;;
    show_cql_grants.py)
      _mkshim "${SANDBOX}/cql/bin/cqlsh" 'if [ "${1:-}" = "--version" ]; then echo "cqlsh 6.1"; exit 0; fi; if [[ "$*" == *"system_auth.roles"* ]]; then printf " role | member_of\n------+-----------\n app  | null\n"; else printf " role | resource | permissions\n------+----------+-------------\n app  | data     | {\x27SELECT\x27}\n"; fi'
      (cd "${SANDBOX}/cql" && CQLSH_PATH="${SANDBOX}/cql/bin/cqlsh" python3 "$f" >/dev/null)
      grep -q "GRANT SELECT" "${SANDBOX}/cql/grants_cassandra_from_cqlsh.cql" ;;
    tree_s3.py)
      _mkshim "${SANDBOX}/s3/aws" 'echo "2026-11-23 10:00:00 1024 KiB backup/db.sql"'
      PATH="${SANDBOX}/s3:$PATH" python3 "$f" my-bucket | grep -q "db.sql" ;;
    mkdocs_hooks.py)
      python3 -c 'import importlib.util,sys; sp=importlib.util.spec_from_file_location("m",sys.argv[1]); m=importlib.util.module_from_spec(sp); sp.loader.exec_module(m); assert m.gfm_slugify("Hello World")=="hello-world" and "!!! note" in m.convert_github_alerts("> [!NOTE]\n> T\n")' "$f" ;;
    build_versioned_docs.py)
      python3 "$f" --help >/dev/null
      python3 -c 'import importlib.util,sys; sp=importlib.util.spec_from_file_location("b",sys.argv[1]); m=importlib.util.module_from_spec(sp); sp.loader.exec_module(m); assert m.parse_semver_tag("v1.0.0")==(1,0,0) and "ErrorDocument 404" in m.render_htaccess("v1.0.0")' "$f" ;;
    *) return 1 ;;
  esac
}

_beh_ora() {
  mkdir -p "${SANDBOX}/ora"
  printf 'CREATE TABLE "T1" ("ID" NUMBER, "NAME" VARCHAR2(50 BYTE), "D" DATE) SEGMENT CREATION IMMEDIATE TABLESPACE "USERS";\n' > "${SANDBOX}/ora/bcr_ddl.sql"
  (cd "${SANDBOX}/ora" && bash "${REPO_ROOT}/scripts/bin/ora2mariadb.sh" >/dev/null)
  grep -q "VARCHAR" "${SANDBOX}/ora/bcr_ddl_mariadb.sql"
}
_beh_ssl() {
  bash "${REPO_ROOT}/scripts/3_database/4a_mysql_server_ssl_access.sh" "${SANDBOX}/ssl" >/dev/null 2>&1
  openssl verify -CAfile "${SANDBOX}/ssl/ca-cert.pem" "${SANDBOX}/ssl/server-cert.pem" >/dev/null
}
_beh_cc() {
  _mkshim "${SANDBOX}/cc200/mysql" 'if [[ "$*" == *"wsrep_local_state"* ]]; then echo "4"; else echo "OFF"; fi'
  _mkshim "${SANDBOX}/cc503/mysql" 'if [[ "$*" == *"wsrep_local_state"* ]]; then echo "1"; else echo "ON"; fi'
  PATH="${SANDBOX}/cc200:$PATH" bash "${REPO_ROOT}/scripts/bin/clustercheck" | grep -q "HTTP/1.1 200 OK"
  set +e; local out503; out503="$(PATH="${SANDBOX}/cc503:$PATH" bash "${REPO_ROOT}/scripts/bin/clustercheck")"; local rc503=$?; set -e
  [ "${rc503}" -eq 1 ] && echo "${out503}" | grep -q "HTTP/1.1 503 Service Unavailable"
}

while IFS= read -r rel; do
  matches "$rel" && check_sh "$rel" || true
done < <(cd "${REPO_ROOT}" && { find scripts -type f -name '*.sh'; [ -f scripts/bin/clustercheck ] && echo "scripts/bin/clustercheck"; [ -f scripts/bin/mysqlcheck ] && echo "scripts/bin/mysqlcheck"; } | sort -u)

while IFS= read -r rel; do
  matches "$rel" && run_rc 0 "${rel} (source under set -e)" bash -c 'set -e; source "$1"' _ "${REPO_ROOT}/${rel}" || true
done < <(cd "${REPO_ROOT}" && find scripts -maxdepth 2 -type f -name 'utils*.sh' | sort)

while IFS= read -r rel; do
  matches "$rel" || continue
  if [ ! -s "${REPO_ROOT}/${rel}" ] || grep -q $'\r' "${REPO_ROOT}/${rel}"; then
    TOTAL=$((TOTAL + 1)); FAILED=$((FAILED + 1)); printf '[FAIL] %s: empty or CRLF\n' "${rel}" >&2; continue
  fi
  run_rc 0 "${rel} (py_compile)" python3 -m py_compile "${REPO_ROOT}/${rel}"
  run_rc 0 "${rel} (smoke)" _smoke_py "${REPO_ROOT}/${rel}"
done < <(cd "${REPO_ROOT}" && find scripts -type f -name '*.py' | sort)

if matches "scripts/bin/check_mysql_health.pl" && [ -f "${REPO_ROOT}/scripts/bin/check_mysql_health.pl" ]; then
  run_rc 0 "scripts/bin/check_mysql_health.pl (perl -c)" env PERL5LIB="${SANDBOX}/perl_inc" perl -c "${REPO_ROOT}/scripts/bin/check_mysql_health.pl"
fi

matches "scripts/bin/ora2mariadb.sh" && run_rc 0 "behavior: ora2mariadb.sh" _beh_ora || true
matches "scripts/3_database/4a_mysql_server_ssl_access.sh" && run_rc 0 "behavior: 4a_mysql_server_ssl_access.sh + openssl verify" _beh_ssl || true
for s in mbbackup.sh mbrestore.sh lgbackup.sh lgrestore.sh; do
  matches "scripts/bin/${s}" && run_rc 0 "behavior: ${s} -l" env BCK_DIR="${SANDBOX}/empty_bck" bash "${REPO_ROOT}/scripts/bin/${s}" -l || true
done
matches "scripts/bin/maria-pitr-restore.sh" && run_rc 1 "behavior: maria-pitr-restore.sh (missing args)" bash "${REPO_ROOT}/scripts/bin/maria-pitr-restore.sh" || true
if matches "scripts/bin/sync_pg_databases.sh"; then
  run_rc 1 "behavior: sync_pg_databases.sh (--source invalid_format)" bash "${REPO_ROOT}/scripts/bin/sync_pg_databases.sh" --source invalid_format
  run_rc 1 "behavior: sync_pg_databases.sh (--config nonexistent)" bash "${REPO_ROOT}/scripts/bin/sync_pg_databases.sh" --config "${SANDBOX}/nonexistent.conf"
fi
matches "scripts/bin/clustercheck" && run_rc 0 "behavior: clustercheck (HTTP 200 & HTTP 503)" _beh_cc || true

echo "Tested ${PASSED}/${TOTAL} scripts: ${FAILED} failed"
[ "${FAILED}" -eq 0 ]
