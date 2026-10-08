import 'package:flutter/foundation.dart';

import '../models/startup_config.dart';

/// A LibreChat release number, `MAJOR.MINOR.PATCH` with an optional
/// prerelease such as `rc4` (Req 6.4).
///
/// Ordering follows semver precedence, except that a prerelease identifier
/// also splits between letter and digit runs, so `rc9 < rc10`. Equality and
/// [hashCode] agree with [compareTo].
@immutable
class Version implements Comparable<Version> {
  const Version(this.major, this.minor, this.patch, [this.prerelease]);

  final int major;
  final int minor;
  final int patch;

  /// The text after `-`, as written, or null for a release.
  final String? prerelease;

  static final _pattern = RegExp(
    r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
  );
  static final _runs = RegExp(r'\d+|\D+');
  static final _digits = RegExp(r'^\d+$');

  /// Parses `0.8.8`, `v0.8.8-rc4` or `v0.8.8-rc4+build`, dropping the build
  /// metadata. Anything else is null.
  static Version? parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final major = int.tryParse(match[1]!);
    final minor = int.tryParse(match[2]!);
    final patch = int.tryParse(match[3]!);
    if (major == null || minor == null || patch == null) return null;
    return Version(major, minor, patch, match[4]);
  }

  /// True when major, minor and patch match, whatever the prerelease.
  bool sameRelease(Version other) =>
      major == other.major && minor == other.minor && patch == other.patch;

  /// The prerelease identifiers split on `.` and between letter and digit
  /// runs, with numeric ones stripped of leading zeros.
  List<String> get _identifiers => [
    for (final part in prerelease?.split('.') ?? const <String>[])
      for (final run in _runs.allMatches(part)) _normalize(run[0]!),
  ];

  static String _normalize(String id) {
    if (!_digits.hasMatch(id)) return id;
    final trimmed = id.replaceFirst(RegExp(r'^0+'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }

  /// Numeric identifiers compare numerically and sort before alphanumeric
  /// ones; alphanumeric ones compare by code unit.
  static int _compareIdentifier(String a, String b) {
    final aNumeric = _digits.hasMatch(a);
    final bNumeric = _digits.hasMatch(b);
    if (aNumeric && bNumeric) {
      // Both are normalized, so a longer one is larger.
      final byLength = a.length.compareTo(b.length);
      return byLength != 0 ? byLength : a.compareTo(b);
    }
    if (aNumeric) return -1;
    if (bNumeric) return 1;
    return a.compareTo(b);
  }

  @override
  int compareTo(Version other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    final mine = _identifiers;
    final theirs = other._identifiers;
    // A release is higher than any of its prereleases.
    if (mine.isEmpty || theirs.isEmpty) {
      return theirs.length.compareTo(mine.length).sign;
    }
    for (var i = 0; i < mine.length && i < theirs.length; i++) {
      final order = _compareIdentifier(mine[i], theirs[i]);
      if (order != 0) return order.sign;
    }
    return mine.length.compareTo(theirs.length);
  }

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator >=(Version other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, Object.hashAll(_identifiers));

  @override
  String toString() =>
      '$major.$minor.$patch${prerelease == null ? '' : '-$prerelease'}';
}

/// The Target_Version: the LibreChat release this App is built for, the
/// `tag=` line of UPSTREAM_VERSION.
const targetVersion = Version(0, 8, 8, 'rc4');

// Generated 2026-10-08 from the v* tags of danny-avila/LibreChat. The design's
// `gh api repos/danny-avila/LibreChat/tags --paginate --jq '.[] | "\(.commit.sha) \(.name)"'`
// was run as its curl equivalent (gh was unavailable):
//   for p in 1 2; do curl -sL "https://api.github.com/repos/danny-avila/LibreChat/tags?per_page=100&page=$p"; done \
//     | jq -rs 'add | .[] | select(.name | startswith("v")) | "\(.commit.sha) \(.name)"'
// Regenerate when the Target_Version moves (add pages while the Link header has rel="next").

/// Release commit sha → its tag, for Servers that report only
/// `buildInfo.commit`.
const Map<String, String> releaseCommits = {
  'e8f3be08623663d4ad7f7241e693c94469b63bb0': 'v0.8.8',
  '361553f3322d7b9bb547d0a9c2c5aaefc2934901': 'v0.8.8-rc4',
  '1df448481075d37484f11c4751dc3f60314ee651': 'v0.8.8-rc3',
  'f9f1b2fb951a99e1fd01ee7291304a0370ea6132': 'v0.8.8-rc2',
  'eaef87fa2684025627e25d649a56f4f2a63417a7': 'v0.8.8-rc1',
  '9e74cc0e57b395926122bd4062c1fcedc48ed465': 'v0.8.7',
  '055585f9f1f43c71b8f883a2c89e905d124d0721': 'v0.8.7-rc1',
  '566e20b613389600a7975fd8f7c1bffbe54f06c8': 'v0.8.6',
  '947bfa4c40e6b8c84346d23c1678cd83071c5179': 'v0.8.6-rc1',
  '9ccc8d9bef407f9a769f07a3756ec4b95ac13f80': 'v0.8.5',
  '4f133f8955245845c2b29cb7e84f6d7f41bd5199': 'v0.8.5-rc1',
  '0736ff26686e911c9785a237c63a799db1813f0b': 'v0.8.4',
  'b5a55b23a4b2f5f6428679b1ee358f18b02d51d8': 'v0.8.4-rc1',
  'cfbe812d63451c1578faa9a13b7e77e0c9a9789b': 'v0.8.3',
  '7e85cf71bd271d552576b2ba23ec1fb72bdcaaa1': 'v0.8.3-rc2',
  '9eeec6bc4f5e856ac65f50784254d484b2808622': 'v0.8.3-rc1',
  'efbc088642afb69540efae9518b66e07760b23b7': 'v0.8.2',
  'b70528f59aca7b64d39027a36d970e57cc96158b': 'v0.8.2-rc3',
  '24e8a258cd8fa1ff42c02cf15408079f1dbe07b0': 'v0.8.2-rc2',
  'da108155663f8aaab4e9d83e8a45aba273f0f7aa': 'v0.8.2-rc1',
  'b288d81f5a4625403bc880e93059d90d9aa51fe3': 'v0.8.1',
  'f0f81945fb80e821f839d8fb29ccae0aaa471511': 'v0.8.1-rc2',
  '1e53ffa7ea8b25702b70e822d592da0bffb18199': 'v0.8.1-rc1',
  'b7d13cec6f3a63c7b81f5781f6b5cab289e33d70': 'v0.8.0',
  'dd93db40bc244301edd7d002c94b4e77a385a559': 'v0.8.0-rc4',
  'e1ad235f17f9ae60b137d039746577cfd31f8bd7': 'v0.8.0-rc3',
  '007570b5c61e0049c177a7bec44196d310a21b4b': 'v0.8.0-rc2',
  '4175a3ea193e547507d9d76d7dd80929c12030d3': 'v0.8.0-rc1',
  'bef5c26bed4e5053bdf1936d6ded2c77035c6ee5': 'v0.7.9',
  '9c70d1db969949a5f2f427f447899151e7055638': 'v0.7.9-rc1',
  'f7777a2723e8e51f3ff464d4e672db46905964a5': 'v0.7.8',
  '18dc3f8686661dde46d3d347d604c2dab970a68e': 'v0.7.8-rc1',
  '4d04904af36734f3e6703cfb61c183929f9de560': 'v0.7.7',
  '46f034250d882b69b6aa7d47850e9f31b689d1de': 'v0.7.7-rc1',
  '9b118d42de3f99e9c8c85d0beb46d4ae5fd74a4c': 'v0.7.6',
  '2875380bf16b56e0943c34f61f06e1e09e3fb541': 'v0.7.6-rc1',
  '600d21780bfced4d2146ab556fa4de0dcaef55ce': 'v0.7.5',
  '020995514e667ec0b7e550e34f6b61fda62c62e6': 'v0.7.5-rc2',
  '80e1bdc2824f8be08587a6ccbd999da79e6396a1': 'v0.7.5-rc1',
  'cf69b7ef857e30a539b340801248d2fa58b8a9ad': 'v0.7.4',
  '302b28fc9b505dd27c8d88feb7e77ea8d44a3dc7': 'v0.7.4-rc1',
  '0294cfc881513d9763857e52fce328e905cc8a08': 'v0.7.3',
  '37ae484fbc5f71ea3109296ab2ca88321b0e4acc': 'v0.7.3-rc2',
  'e42709bd1f9e116e806418c359694b452d206aa7': 'v0.7.3-rc',
  '4a32d7466aaaea5ba1fbe8b8e38ef115796166c0': 'v0.7.2',
  'cdab1e9cdaeb6bd5c3259184b24da1a9a576a26b': 'v0.7.1',
  '49753a35e5f7fd3a7faa0efef9d2467c8794df71': 'v0.7.0',
  '98064244bf25c3996cda4cfd1b6da1847a1f82f8': 'v0.6.10',
  '6ccf4d6ed21c12621164f1782446eaa57d8bbabd': 'v0.6.9',
  '5ac89b8f0ee421b9f26ce099474fe55323ef0dab': 'v0.6.6',
  '5b283622826ca12599ed7690ec1b53223d5cec70': 'v0.6.5',
  'adbeb46399f6fb434687582360e1a44777b578f0': 'v0.6.1',
  '00e0091f7aeb6a1bedbe2997b05d36117785aaa7': 'v0.6.0',
  '8580f1c3d35ac0237292e58c4e06c911b55c30fa': 'v0.5.9',
  'd672ac690d469cfabf272b96699902803bb827cb': 'v0.5.8',
  'f101419af392b1565299c5ed4e16a9a6a794d80f': 'v0.5.7',
  '94764c9c2acfa21e67a5303f94c2b714f7b5104f': 'v0.5.6',
  '514f625b8f371bd0262222f03c96f21243f769c0': 'v0.5.5',
  '732a0b80297889c3ce7a025c2e4a6b78ddab50a1': 'v0.5.4',
  '2607f157d3b391f0c5063aa2864a4158bf595186': 'v0.5.3',
  '83eea4825b75433277f789830005d5995bb955b8': 'v0.5.2',
  'f1f33de4db7c35b7223977c3e5c0243b02a21eac': 'v0.5.1',
  'e4c91dfbea27e7ebc07d464169dceb7a7cccddb4': 'v0.5.0',
  '47d0184990f6e1b645941bdccf29fe455883bb95': 'v0.4.8',
  'fd5afc09a26aaf156735c7b1a3e8b8b287bceca6': 'v0.4.7',
  'a9444b66a157fe122833cbfae8cebfacbd933208': 'v0.4.6',
  'dbf45196eebfbc1f341ad56e91d2f8412d648d34': 'v0.4.5',
  '501a15a18f7104ced77b2fc6d0367434bfc5c16e': 'v0.4.4',
  '49041e16c7923bb6c8bfb0730fcbe518e1b62ffd': 'v0.4.3',
  '94ad31dce3906bb3a28804d36845b787258f78fe': 'v0.4.2',
  '03d871316a2d0fbf38fc16a000403985c50cb25e': 'v0.4.1',
  '960e8c4724eb0055cc18011aa55e5b46944bdeb6': 'v0.4.0',
  'f5ff91cfbd3e679151d6693f158e1c503dad0f90': 'v0.3.3',
  'b4d451d7ae25c34e82b1ce625afd111844f0c726': 'v0.3.0',
  'cf2bab31cf56f8827b4c8c12b030c33762766453': 'v0.2.0',
  'e8e512a4515857315fdc34dd78e8580497877447': 'v0.1.1',
  'c6fb3018e78f74cb5d6a70a2461f50fa8a68475b': 'v0.1.0',
  '90b74aff2e85deb1cb865c94393d608f8fc8fc7d': 'v0.0.6',
  '1308ef1394dc11f56abea195abc8a7f7d1437643': 'v0.0.5',
  '346c63617b073b3f95fe1db051bad91244ec0dfe': 'v0.0.4',
  '5d65427a6eba02de0c4812064adfa890c06475ba': 'v0.0.3',
  '12cf3405e4a41451dc8477e770968c533ffae09e': 'v0.0.2',
  '5af03bb3d8fb8556403d59f847e147dac5d4019e': 'v0.0.1',
};

final _shaPrefix = RegExp(r'^[0-9a-f]{7,}$');

/// The release whose commit starts with [commit], or null when [commit] is
/// shorter than 7 hex digits or matches no tag or more than one. An
/// ambiguous prefix is unknown so a wrong version is never reported.
Version? versionForCommit(String? commit) {
  final prefix = commit?.trim().toLowerCase();
  if (prefix == null || !_shaPrefix.hasMatch(prefix)) return null;
  final tags = [
    for (final MapEntry(:key, :value) in releaseCommits.entries)
      if (key.startsWith(prefix)) value,
  ];
  return tags.length == 1 ? Version.parse(tags.single) : null;
}

/// The Server_Version: the config's `version` when it parses, else the
/// release of its `buildInfo.commit`, else null (unknown, Req 6.6).
Version? serverVersionOf(StartupConfig config) {
  final version = config.version;
  return (version == null ? null : Version.parse(version)) ??
      versionForCommit(config.buildInfo?.commit);
}
