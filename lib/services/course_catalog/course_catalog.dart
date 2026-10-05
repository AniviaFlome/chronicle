/// Course-catalog lookup: type a university course code, get the official
/// details back (name, credits, instructor, weekly sections, ...).
///
/// ITU reads the public ÖBS pages (no login); Hacettepe reads the public
/// AKTS course-list pages. Both publishers are plain HTML, parsed with
/// package:html exactly like the dining-menu providers.
library;

/// Why a lookup failed. [notFound] covers unknown codes (ITU answers
/// those with HTTP 500); [network] covers transport failures.
/// [crnNotSupported] means the input looks like a CRN (section number):
/// neither university offers a CRN-keyed endpoint — CRNs only appear
/// inside per-branch program tables — so the user must enter the course
/// code and pick the CRN from the section list instead.
enum CourseLookupFailure { invalidCode, notFound, network, crnNotSupported }

/// Valid course-catalog source ids. '' (none) disables catalog lookup;
/// only implemented sources may be selected.
const catalogSourceIds = {'itu'};

class CourseLookupException implements Exception {
  const CourseLookupException(this.failure, [this.message = '']);
  final CourseLookupFailure failure;
  final String message;

  @override
  String toString() => 'CourseLookupException($failure): $message';
}

/// One weekly meeting of a section (e.g. Monday 08:30 - 11:29).
class CourseDaySlot {
  const CourseDaySlot({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
  });

  /// Monday = 1 … Sunday = 7 (matches [DateTime.weekday]).
  final int weekday;
  final int startMinutes;
  final int endMinutes;

  /// Session room; empty when the catalog prints none.
  final String room;
}

/// One CRN / section of a course (ITU program pages list these).
class CourseSection {
  const CourseSection({
    required this.crn,
    required this.code,
    required this.name,
    required this.instructor,
    required this.building,
    required this.room,
    required this.slots,
    this.method,
    this.prerequisites,
    this.quota,
    this.enrolled,
  });

  final String crn;
  final String code;
  final String name;
  final String instructor;
  final String building;

  /// Room of the first session (per-session rooms live on [slots]).
  final String room;
  final List<CourseDaySlot> slots;

  /// Teaching method, e.g. `Fiziksel (Yüz yüze)` (ITU program rows).
  final String? method;
  final String? prerequisites;
  final int? quota;
  final int? enrolled;
}

/// Catalog facts about a course, mapped onto class fields by the editor.
class CatalogCourse {
  const CatalogCourse({
    required this.code,
    required this.name,
    this.nameAlt,
    this.language,
    this.credits,
    this.ects,
    this.theoryHours,
    this.practiceHours,
    this.labHours,
    this.department,
    this.description,
    this.type,
  });

  /// Canonical code as printed by the catalog (e.g. `MAT 103`).
  final String code;

  /// Display name (Turkish for ITU, course-list name for Hacettepe).
  final String name;

  /// English name, when the catalog prints one.
  final String? nameAlt;
  final String? language;
  final double? credits;
  final double? ects;
  final int? theoryHours;
  final int? practiceHours;
  final int? labHours;
  final String? department;
  final String? description;

  /// E.g. `Zorunlu` / `Seçmeli` (Hacettepe only).
  final String? type;
}

/// True when [raw] looks like a CRN (section number) rather than a course
/// code: bare digits (`10173`) or an explicit `CRN` prefix (`CRN 10173`).
/// Neither university has a CRN-keyed endpoint, so callers surface the
/// [CourseLookupFailure.crnNotSupported] guidance instead of querying.
bool looksLikeCrn(String raw) {
  final t = raw.trim().toUpperCase();
  if (RegExp(r'^\d{2,6}$').hasMatch(t)) return true;
  return RegExp(r'^CRN[\s#:.]*\d{2,6}$').hasMatch(t);
}

/// Parses user input like `MAT 103E`, `mat103`, `TRO 601` into a
/// `(branch, number)` pair. The trailing language suffix (E) is dropped:
/// ITU's search only accepts the numeric part.
({String branch, String number})? parseCourseCode(String raw) {
  final match = RegExp(
    r'^\s*([A-Za-zÇĞİÖŞÜçğıöşü]+)\s*(\d{2,4})',
  ).firstMatch(raw);
  if (match == null) return null;
  return (
    branch: match.group(1)!.toUpperCase(),
    number: match.group(2)!,
  );
}
