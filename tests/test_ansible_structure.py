"""Unit tests verifying Ansible playbooks, role structure, YAML validity, handlers, and variables."""

from __future__ import annotations

import pathlib
import unittest
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]


class TestAnsiblePlaybooksSyntax(unittest.TestCase):
    """Tier 1: Ansible playbook YAML syntax compilation and structure."""

    def _collect_yaml_files(self) -> list[pathlib.Path]:
        yaml_files: list[pathlib.Path] = []
        for search_dir in (ROOT / "ansible", ROOT / "MariaDB" / "ansible"):
            if search_dir.is_dir():
                for ext in ("*.yml", "*.yaml"):
                    yaml_files.extend(search_dir.rglob(ext))
        return sorted(yaml_files)

    def test_all_ansible_yaml_files_are_valid(self) -> None:
        """Verify all playbooks, tasks, handlers, and defaults in ansible/ parse cleanly as valid YAML."""
        yaml_files = self._collect_yaml_files()
        self.assertGreater(len(yaml_files), 0, "Expected to find Ansible YAML files")

        parse_errors: list[str] = []
        for yml_file in yaml_files:
            rel = yml_file.relative_to(ROOT).as_posix()
            try:
                content = yml_file.read_text(encoding="utf-8")
                yaml.safe_load(content)
            except Exception as e:
                parse_errors.append(f"{rel}: {e}")

        self.assertEqual(
            parse_errors,
            [],
            f"YAML syntax parsing failed on {len(parse_errors)} files:\n" + "\n".join(parse_errors),
        )


class TestAnsibleRoleStructure(unittest.TestCase):
    """Tier 2 & 3: Ansible role directory layout, defaults, handlers, and variable safety (Finding 8)."""

    def test_mysql_servers_role_has_required_structure(self) -> None:
        """Verify ansible/roles/mysql_servers contains tasks, defaults, and handlers directories (Finding 8)."""
        role_dir = ROOT / "ansible" / "roles" / "mysql_servers"
        self.assertTrue(role_dir.is_dir(), "ansible/roles/mysql_servers directory must exist")

        tasks_main = role_dir / "tasks" / "main.yml"
        defaults_main = role_dir / "defaults" / "main.yml"
        handlers_main = role_dir / "handlers" / "main.yml"

        self.assertTrue(tasks_main.is_file(), "roles/mysql_servers/tasks/main.yml must exist")
        self.assertTrue(defaults_main.is_file(), "roles/mysql_servers/defaults/main.yml must exist")
        self.assertTrue(handlers_main.is_file(), "roles/mysql_servers/handlers/main.yml must exist")

    def test_mysql_cluster_role_has_required_structure(self) -> None:
        """Verify ansible/roles/mysql_cluster contains tasks, defaults, and handlers directories (Finding 8)."""
        role_dir = ROOT / "ansible" / "roles" / "mysql_cluster"
        self.assertTrue(role_dir.is_dir(), "ansible/roles/mysql_cluster directory must exist")

        tasks_main = role_dir / "tasks" / "main.yml"
        defaults_main = role_dir / "defaults" / "main.yml"
        handlers_main = role_dir / "handlers" / "main.yml"

        self.assertTrue(tasks_main.is_file(), "roles/mysql_cluster/tasks/main.yml must exist")
        self.assertTrue(defaults_main.is_file(), "roles/mysql_cluster/defaults/main.yml must exist")
        self.assertTrue(handlers_main.is_file(), "roles/mysql_cluster/handlers/main.yml must exist")

    def test_no_broken_include_vars_in_roles(self) -> None:
        """Verify roles do not contain broken include_vars pointing to non-existent paths (Finding 8)."""
        target = ROOT / "ansible" / "roles" / "mysql_cluster" / "tasks" / "main.yml"
        if target.is_file():
            content = target.read_text(encoding="utf-8")
            self.assertNotIn(
                "../../group_vars/mysql_servers.yml",
                content,
                "mysql_cluster role contains broken include_vars pointing to ../../group_vars/mysql_servers.yml",
            )

    def test_no_empty_environment_mapping_in_mysql_servers(self) -> None:
        """Verify mysql_servers/tasks/main.yml does not contain invalid empty 'pass:' mapping (Finding 8)."""
        target = ROOT / "ansible" / "roles" / "mysql_servers" / "tasks" / "main.yml"
        if target.is_file():
            content = target.read_text(encoding="utf-8")
            self.assertNotRegex(
                content,
                r"environment:\s*\n(\s*#.*\n)*\s*pass:\s*(\n|$)",
                "mysql_servers task must not contain empty 'pass:' key in environment block",
            )


class TestAnsibleIntegrationContracts(unittest.TestCase):
    """Tier 3 & 4: Playbook-to-role wiring, notification contracts, and canonical tree consolidation."""

    def test_innodb_cluster_playbook_location_and_role_name(self) -> None:
        """Verify playbook_innodb_cluster_group.yml is in ansible/ and targets role 'mysql_servers' (Finding 8, 14)."""
        canonical_playbook = ROOT / "ansible" / "playbook_innodb_cluster_group.yml"
        legacy_playbook = ROOT / "MariaDB" / "ansible" / "playbook_innodb_cluster_group.yml"

        target_playbook = canonical_playbook if canonical_playbook.is_file() else legacy_playbook
        self.assertTrue(
            target_playbook.is_file(),
            "playbook_innodb_cluster_group.yml must exist in ansible/ (or MariaDB/ansible/)",
        )

        content = target_playbook.read_text(encoding="utf-8")
        data = yaml.safe_load(content)
        self.assertIsInstance(data, list, "Playbook must be a list of plays")

        # Find play targeting mysql_servers
        server_roles: list[str] = []
        for play in data:
            if isinstance(play, dict) and "roles" in play:
                for r in play["roles"]:
                    if isinstance(r, str):
                        server_roles.append(r)
                    elif isinstance(r, dict) and "role" in r:
                        server_roles.append(r["role"])

        # Role name must be 'mysql_servers', not mismatched singular 'mysql_server'
        self.assertNotIn(
            "mysql_server",
            server_roles,
            "Playbook references non-existent role 'mysql_server'; must be aligned with 'mysql_servers'",
        )

    def test_role_handlers_define_all_notified_targets(self) -> None:
        """Verify that any notify targets in role tasks are defined in handlers/main.yml (Finding 8)."""
        for role_name in ("mysql_servers", "mysql_cluster"):
            role_dir = ROOT / "ansible" / "roles" / role_name
            tasks_file = role_dir / "tasks" / "main.yml"
            handlers_file = role_dir / "handlers" / "main.yml"

            if not tasks_file.is_file():
                continue

            tasks_content = tasks_file.read_text(encoding="utf-8")
            # Collect notify targets
            notified: set[str] = set()
            try:
                tasks_data = yaml.safe_load(tasks_content)
                if isinstance(tasks_data, list):
                    for task in tasks_data:
                        if isinstance(task, dict) and "notify" in task:
                            notify_val = task["notify"]
                            if isinstance(notify_val, list):
                                notified.update(notify_val)
                            elif isinstance(notify_val, str):
                                notified.add(notify_val)
            except Exception:
                pass

            if notified:
                self.assertTrue(
                    handlers_file.is_file(),
                    f"Role '{role_name}' tasks notify handlers {notified}, but handlers/main.yml is missing",
                )
                handlers_content = handlers_file.read_text(encoding="utf-8")
                handlers_data = yaml.safe_load(handlers_content)
                handler_names = set()
                if isinstance(handlers_data, list):
                    for h in handlers_data:
                        if isinstance(h, dict) and "name" in h:
                            handler_names.add(h["name"])
                        if isinstance(h, dict) and "listen" in h:
                            handler_names.add(h["listen"])

                missing = notified - handler_names
                self.assertEqual(
                    missing,
                    set(),
                    f"Role '{role_name}' notifies handlers not defined in handlers/main.yml: {missing}",
                )


if __name__ == "__main__":
    unittest.main()
