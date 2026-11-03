import json
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / 'dot_local/bin/executable_agent-settings-sync'
POLICY = SOURCE / 'dot_agents/settings-policy.json'


class SettingsSyncTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.claude = self.root / '.claude/settings.json'
        self.codex = self.root / '.codex/config.toml'
        self.claude.parent.mkdir()
        self.codex.parent.mkdir()
        self.settings = {
            'permissions': {'deny': ['Read(**/.env*)'], 'defaultMode': 'auto'},
            'hooks': {'SessionStart': [{'command': 'existing-hook'}]},
            'enabledPlugins': {'unrelated@marketplace': True},
            'autoMode': {'environment': ['Trusted repo: old-project', '**Trusted internal domains**: local.example.invalid'], 'hard_deny': ['existing-rule']},
        }
        self.claude.write_text(json.dumps(self.settings))
        self.codex.write_text('# preserve this comment\nmodel = "existing-model"\n\n'
                              '[plugins."i-have-adhd@i-have-adhd"]\nenabled = true # retain\n'
                              '\n[plugins."unrelated@marketplace"]\nenabled = true\n')

    def tearDown(self):
        self.temporary.cleanup()

    def run_sync(self, *args):
        return subprocess.run(['python3', str(SCRIPT), '--home', str(self.root),
                               '--policy', str(POLICY), *args], capture_output=True, text=True)

    def test_preserves_permissions_hooks_and_unowned_settings(self):
        self.assertEqual(self.run_sync().returncode, 0)
        actual = json.loads(self.claude.read_text())
        self.assertEqual(actual['permissions'], self.settings['permissions'])
        self.assertEqual(actual['hooks'], self.settings['hooks'])
        self.assertEqual(actual['autoMode']['hard_deny'], ['existing-rule'])
        self.assertIn('$defaults', actual['autoMode']['environment'])
        self.assertNotIn('Trusted repo: old-project', actual['autoMode']['environment'])
        self.assertIn('**Trusted internal domains**: local.example.invalid', actual['autoMode']['environment'])
        self.assertTrue(actual['enabledPlugins']['unrelated@marketplace'])
        for name in json.loads(POLICY.read_text())['disabled_plugins']:
            self.assertFalse(actual['enabledPlugins'][name])
            self.assertFalse(tomllib.loads(self.codex.read_text())['plugins'][name]['enabled'])
        self.assertEqual(tomllib.loads(self.codex.read_text())['model'], 'existing-model')
        self.assertIn('# preserve this comment', self.codex.read_text())
        self.assertIn('false # retain', self.codex.read_text())
        self.assertTrue(tomllib.loads(self.codex.read_text())['plugins']['unrelated@marketplace']['enabled'])

    def test_second_run_leaves_bytes_unchanged(self):
        self.assertEqual(self.run_sync().returncode, 0)
        before = (self.claude.read_bytes(), self.codex.read_bytes())
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertEqual(before, (self.claude.read_bytes(), self.codex.read_bytes()))

    def test_dry_run_does_not_write(self):
        before = (self.claude.read_bytes(), self.codex.read_bytes())
        self.assertEqual(self.run_sync('--dry-run').returncode, 0)
        self.assertEqual(before, (self.claude.read_bytes(), self.codex.read_bytes()))

    def test_invalid_toml_leaves_claude_unchanged(self):
        before = self.claude.read_bytes()
        self.codex.write_text('[invalid\n')
        self.assertNotEqual(self.run_sync().returncode, 0)
        self.assertEqual(before, self.claude.read_bytes())

    def test_missing_configs_are_created(self):
        self.claude.unlink()
        self.codex.unlink()
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertIn('$defaults', json.loads(self.claude.read_text())['autoMode']['environment'])
        self.assertTrue(tomllib.loads(self.codex.read_text())['plugins'])


if __name__ == '__main__':
    unittest.main()
