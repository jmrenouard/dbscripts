"""Unit tests verifying Python Docker manager utility safety, bug checks, and contracts (Finding 7)."""

from __future__ import annotations

import ast
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class TestPythonDockerManager(unittest.TestCase):
    """Tier 2 & 4: Python Docker management utility safety and bug checks (Finding 7)."""

    def test_mysql_docker_no_except_e_name_error(self) -> None:
        """Verify docker/mysql_docker.py does not contain invalid 'except e:' construct (Finding 7)."""
        target = ROOT / "docker" / "mysql_docker.py"
        self.assertTrue(target.is_file(), "docker/mysql_docker.py must exist")
        content = target.read_text(encoding="utf-8")

        # In Python 3, 'except e:' attempts to catch an exception class named e (which causes NameError)
        tree = ast.parse(content, filename=str(target))
        invalid_excepts = []
        for node in ast.walk(tree):
            if isinstance(node, ast.ExceptHandler):
                if isinstance(node.type, ast.Name) and node.type.id == "e" and node.name is None:
                    invalid_excepts.append(f"Line {node.lineno}: except e:")

        self.assertEqual(
            invalid_excepts,
            [],
            f"Found invalid 'except e:' handlers in {target}:\n" + "\n".join(invalid_excepts),
        )

    def test_mysql_docker_info_passes_password_to_generate_bash_alias(self) -> None:
        """Verify 'info' command in mysql_docker.py passes password to generate_bash_alias (Finding 7)."""
        target = ROOT / "docker" / "mysql_docker.py"
        self.assertTrue(target.is_file(), "docker/mysql_docker.py must exist")
        content = target.read_text(encoding="utf-8")

        # In main(), info command must not call generate_bash_alias(args.env_name, args.port) without password
        self.assertNotRegex(
            content,
            r"generate_bash_alias\(\s*args\.env_name\s*,\s*args\.port\s*\)",
            "generate_bash_alias in 'info' command must pass password parameter (3 arguments required)",
        )

    def test_mysql_docker_remove_environment_does_not_delete_shared_images(self) -> None:
        """Verify remove_environment does not forcefully delete shared base container images (Finding 7)."""
        target = ROOT / "docker" / "mysql_docker.py"
        self.assertTrue(target.is_file(), "docker/mysql_docker.py must exist")
        content = target.read_text(encoding="utf-8")

        # Should not blindly call docker_client.images.remove
        self.assertNotIn(
            "docker_client.images.remove",
            content,
            "remove_environment should not delete shared base docker images",
        )

    def test_mysql_docker_password_generation_uses_secrets(self) -> None:
        """Verify generate_password uses cryptographically secure secrets module (Finding 7)."""
        target = ROOT / "docker" / "mysql_docker.py"
        self.assertTrue(target.is_file(), "docker/mysql_docker.py must exist")
        content = target.read_text(encoding="utf-8")

        self.assertIn(
            "secrets",
            content,
            "mysql_docker.py generate_password should use secrets module for secure credential generation",
        )


if __name__ == "__main__":
    unittest.main()
