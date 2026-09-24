// The app encodes `user_context` and `todays_menu` in snake_case; the worker
// reads camelCase. Without this alias the context (hidden sessions,
// availability, today's menu) never arrived and every filter built on it
// silently did nothing.
export function aliasSnakeCaseFields(record: Record<string, unknown>): void {
  if (record.userContext === undefined && record.user_context !== undefined) record.userContext = record.user_context;
  if (record.todaysMenu === undefined && record.todays_menu !== undefined) record.todaysMenu = record.todays_menu;
}
