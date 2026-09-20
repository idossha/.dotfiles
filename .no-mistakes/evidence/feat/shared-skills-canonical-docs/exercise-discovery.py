from pathlib import Path
import tempfile, shutil, subprocess, tomllib, json
repo = Path.cwd()
evidence = Path('/Users/idohaber/.no-mistakes/evidence/01M308ZH5QYJGQ3R51BB4ZFDXR')
lines = ['Isolated installation through the public sync CLI; live home untouched.']
with tempfile.TemporaryDirectory(prefix='.test-discovery-', dir=repo) as scratch:
    root = Path(scratch)
    source = root / 'agent'
    shutil.copytree(repo / 'agent', source, ignore=shutil.ignore_patterns('.venv', 'local', '__pycache__'))
    destination = root / 'home'
    command = [str(repo / 'agent/.venv/bin/python'), str(source / 'scripts/agent_config.py'), '--agent-dir', str(source), '--destination', str(destination), '--playbook', '/Users/idohaber/00_development/agentic-rules']
    for extra in ([], ['--check-installed']):
        result = subprocess.run(command + extra, text=True, capture_output=True)
        lines.extend(['$ python agent_config.py ' + ' '.join(extra) + ' (isolated source/destination)', result.stdout, result.stderr])
        assert result.returncode == 0
    names = ['ponytail', 'ponytail-review', 'ponytail-audit', 'ponytail-debt', 'ponytail-gain', 'ponytail-help']
    for name in names:
        for discovery in ['.claude/skills', '.agents/skills']:
            link = destination / discovery / name
            assert link.is_symlink() and link.resolve() == source / 'skills' / name
            assert (link / 'SKILL.md').read_bytes() == (repo / 'agent/skills' / name / 'SKILL.md').read_bytes()
            lines.append(f'{discovery}/{name} -> agent/skills/{name} (same readable source)')
    cfg = tomllib.loads((destination / '.codex/config.toml').read_text())
    assert cfg['approval_policy'] == 'never'
    assert cfg['sandbox_mode'] == 'danger-full-access'
    assert not (destination / '.codex/config.toml').is_symlink()
    lines.append('Generated Codex settings: ' + json.dumps({k: cfg[k] for k in ['approval_policy', 'sandbox_mode']}))
    for path in ['.codex/AGENTS.md', '.pi/agent/AGENTS.md']:
        assert (destination / path).resolve() == source / 'policy/global.md'
        lines.append(path + ' -> agent/policy/global.md')
    lines.append('\nDelivered Ponytail help card:\n' + (destination / '.agents/skills/ponytail-help/SKILL.md').read_text())
    lines.append('Scope: instruction delivery and link ownership; no model invocation or remote delivery.')
text = '\n'.join(lines)
(evidence / 'shared-skills-installation.txt').write_text(text)
print(text)
