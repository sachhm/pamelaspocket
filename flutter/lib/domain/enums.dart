// Wire values are the enum names, so JSON matches the Expo app
// (e.g. EntryKind.question <-> "question").

enum Role { owner, staff, family }

enum EntryKind { general, mood, important, question, moment }

enum QuestionState { open, resolved }

enum Attachment { none, photo }

enum VoiceNote { none, sample }

enum MessageSource { person, ai }

enum Thread { care, guide }

enum Known { yes, no }

enum Escalation { none, sent }

enum AccessState { active, revoked }

enum RequestKind { appointment, visit, prescription }

enum Reminder { off, on }

enum StorySection { life, personality, routines }

enum FileKind { photo, voice, document }

enum SignInResult { ok, rejected }

enum PinResult { ok, wrong, revoked }

enum Gate { any, household, owner }

enum HandoverSource { person, ai }

enum Onboarding { pending, done }
