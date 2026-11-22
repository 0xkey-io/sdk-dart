// tool/check_brand_residue.dart
//
// Fails when a tracked file mentions the upstream brand outside the allowlist.
//
// Every tracked text file is searched case-insensitively for the upstream brand name and its GitHub
// organization. A matching line passes only if an entry of tool/brand_residue_allowlist.txt covers
// it. Entries that no longer match anything also fail, so the allowlist cannot silently grow stale.
//
// Allowlist format, one entry per line (blank lines and `#` comments are ignored):
//
//     <path glob>                  every matching line in the files is allowed
//     <path glob> :: <regex>       only lines matching the Dart regex are allowed
//
//     dart run tool/check_brand_residue.dart

import 'dart:convert';
import 'dart:io';

const allowlistPath = 'tool/brand_residue_allowlist.txt';
const selfPaths = {'tool/check_brand_residue.dart', allowlistPath};
final pattern = RegExp('turn' 'key|tk' 'hq', caseSensitive: false);

class _Entry {
  _Entry(this.line, this.glob, this.regex) : match = _globToRegExp(glob);

  final int line;
  final String glob;
  final RegExp match;
  final RegExp? regex;
  bool used = false;
}

RegExp _globToRegExp(String glob) {
  final out = StringBuffer();
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (c == '*' && i + 1 < glob.length && glob[i + 1] == '*') {
      out.write('.*');
      i++;
      if (i + 1 < glob.length && glob[i + 1] == '/') i++;
    } else if (c == '*') {
      out.write('[^/]*');
    } else if (c == '?') {
      out.write('[^/]');
    } else {
      out.write(RegExp.escape(c));
    }
  }
  return RegExp('^$out\$');
}

List<_Entry> _loadAllowlist() {
  final entries = <_Entry>[];
  final lines = File(allowlistPath).readAsLinesSync();
  for (var n = 0; n < lines.length; n++) {
    final line = lines[n].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final sep = line.indexOf(' :: ');
    final glob = (sep == -1 ? line : line.substring(0, sep)).trim();
    final regex = sep == -1 ? null : RegExp(line.substring(sep + 4).trim());
    entries.add(_Entry(n + 1, glob, regex));
  }
  return entries;
}

List<String> _trackedFiles() {
  final result = Process.runSync('git', ['ls-files', '-z'],
      stdoutEncoding: utf8, runInShell: false);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return (result.stdout as String)
      .split('\x00')
      .where((p) => p.isNotEmpty)
      .toList();
}

void main() {
  final entries = _loadAllowlist();
  final failures = <String>[];
  for (final path in _trackedFiles()) {
    if (selfPaths.contains(path)) continue;
    if (FileSystemEntity.typeSync(path, followLinks: false) !=
        FileSystemEntityType.file) {
      continue;
    }
    final data = File(path).readAsBytesSync();
    if (data.take(8192).contains(0)) continue;
    final candidates = entries.where((e) => e.match.hasMatch(path)).toList();
    final lines =
        const LineSplitter().convert(utf8.decode(data, allowMalformed: true));
    for (var n = 0; n < lines.length; n++) {
      final text = lines[n];
      if (!pattern.hasMatch(text)) continue;
      final hit = candidates
          .where((e) => e.regex == null || e.regex!.hasMatch(text))
          .firstOrNull;
      if (hit == null) {
        final trimmed = text.trim();
        failures.add(
            '$path:${n + 1}: ${trimmed.length > 160 ? trimmed.substring(0, 160) : trimmed}');
      } else {
        hit.used = true;
      }
    }
    if (pattern.hasMatch(path)) {
      final whole = candidates.where((e) => e.regex == null).firstOrNull;
      if (whole == null) {
        failures.add('$path: upstream brand in the file name');
      } else {
        whole.used = true;
      }
    }
  }
  final stale = entries.where((e) => !e.used).toList();
  if (failures.isNotEmpty) {
    stderr.writeln(
        '${failures.length} line(s) name the upstream brand outside $allowlistPath:');
    stderr.writeln(failures.map((f) => '  $f').join('\n'));
  }
  if (stale.isNotEmpty) {
    stderr.writeln('allowlist entries that match nothing (remove them):');
    stderr.writeln(stale.map((e) => '  line ${e.line}: ${e.glob}').join('\n'));
  }
  if (failures.isNotEmpty || stale.isNotEmpty) exit(1);
  stdout.writeln('brand residue check: ok');
}
