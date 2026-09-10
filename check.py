"""Run every SICP unit's executable self-check: python3 check.py."""

import re
import subprocess
from pathlib import Path


def main():
    root = Path(__file__).resolve().parent
    expected = {
        f"{chapter:02}-{unit:02}"
        for chapter, count in enumerate((6, 9, 8, 6, 6), start=1)
        for unit in range(1, count + 1)
    }
    lessons = sorted(
        path
        for path in (root / "units").iterdir()
        if path.is_dir() and re.fullmatch(r"\d{2}-\d{2}-.+", path.name)
    )
    actual = [path.name[:5] for path in lessons]
    if set(actual) != expected or len(actual) != len(expected):
        raise SystemExit(
            f"Unit coverage mismatch: missing={sorted(expected - set(actual))}, "
            f"unexpected={sorted(set(actual) - expected)}; "
            f"found {len(actual)} directories, expected {len(expected)}"
        )

    failures = 0
    for lesson in lessons:
        script = lesson / "solutions.rkt"
        if not script.is_file() or not (lesson / "README.md").is_file():
            print(f"FAIL {lesson.name}: missing README.md or solutions.rkt")
            failures += 1
            continue
        try:
            result = subprocess.run(
                ["racket", str(script)],
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=60,
            )
        except FileNotFoundError:
            raise SystemExit(
                "Racket not found; install Racket and the sicp package."
            ) from None
        except subprocess.TimeoutExpired:
            print(f"FAIL {lesson.name}: exceeded 60 seconds")
            failures += 1
            continue
        if result.returncode:
            print(f"FAIL {lesson.name}\n{result.stdout}")
            failures += 1
        else:
            print(f"PASS {lesson.name}")
    print(f"{len(lessons) - failures}/{len(lessons)} units passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
