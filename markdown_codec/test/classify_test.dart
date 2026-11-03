import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

void main() {
  test('classify_table', () {
    const cases = <(String, DocArea, String?)>[
      ('PKM/ADR/ADR-001 - X.md', DocArea.knowledge, 'adr'),
      ('PKM/API/Auth.md', DocArea.knowledge, 'api'),
      ('PKM/Architecture/Overview.md', DocArea.knowledge, 'architecture'),
      ('PKM/Business/Rules.md', DocArea.knowledge, 'business'),
      ('PKM/Database/User.md', DocArea.knowledge, 'entity'),
      ('PKM/Domain/Order.md', DocArea.knowledge, 'domain'),
      ('PKM/Glosarium/Istilah.md', DocArea.knowledge, 'glossary'),
      ('Features/Backend/Plan/01 - X Plan.md', DocArea.tracking, 'plan'),
      ('Features/Frontend/Task/02 - Y.md', DocArea.tracking, 'task'),
      ('Test/Scenario/Login.md', DocArea.tracking, 'scenario'),
      ('Test/Run/2026-11-03.md', DocArea.tracking, 'run'),
      ('Confirmation/03 - Z.md', DocArea.tracking, 'confirmation'),
      ('Question/01 - Q.md', DocArea.tracking, 'question'),
      ('Dashboard/Dashboard.md', DocArea.tracking, 'dashboard'),
      ('Guides/PKM.md', DocArea.guide, null),
      ('CLAUDE.md', DocArea.guide, null),
      ('README.md', DocArea.other, null),
      ('PKM/_LLM-Wiki/adr/x.md', DocArea.other, 'mirror'),
      ('Features/_Format/Template - Task.md', DocArea.other, 'template'),
    ];
    for (final (path, area, type) in cases) {
      final c = classifyPath(path, const {});
      expect([c.area, c.type], [area, type], reason: path);
    }
  });

  test('frontmatter_wins', () {
    final c = classifyPath('PKM/ADR/x.md', const {'type': 'note'});
    expect([c.area, c.type], [DocArea.knowledge, 'note']);
  });
}
