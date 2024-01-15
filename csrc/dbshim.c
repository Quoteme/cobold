/*
 * dbshim.c : accounts(id,name) x ledger_entries(id,account_id,...),
 * one INSERT per session, append-only.
 */
#include <sqlite3.h>
#include <string.h>
#include <time.h>

static sqlite3 *g_db = NULL;

static const char *SCHEMA_SQL =
    "CREATE TABLE IF NOT EXISTS accounts ("
    "  account_id   INTEGER PRIMARY KEY,"
    "  account_name TEXT UNIQUE NOT NULL"
    ");"
    "CREATE TABLE IF NOT EXISTS ledger_entries ("
    "  entry_id      INTEGER PRIMARY KEY AUTOINCREMENT,"
    "  account_id    INTEGER NOT NULL REFERENCES accounts(account_id),"
    "  played_at     TEXT NOT NULL,"
    "  final_balance INTEGER NOT NULL,"
    "  overdrafts    INTEGER NOT NULL,"
    "  tier          TEXT NOT NULL,"
    "  won           INTEGER NOT NULL"
    ");";

/* open/create cobold.db; ensure exactly one PLAYER1 account row */
void db_init(int *rc, int *account_id)
{
    *rc = 0;
    *account_id = 0;
    if (sqlite3_open("cobold.db", &g_db) != SQLITE_OK) { *rc = 1; return; }
    if (sqlite3_exec(g_db, SCHEMA_SQL, NULL, NULL, NULL) != SQLITE_OK) { *rc = 2; return; }

    sqlite3_stmt *st;
    sqlite3_prepare_v2(g_db,
        "INSERT OR IGNORE INTO accounts(account_name) VALUES ('PLAYER1');",
        -1, &st, NULL);
    sqlite3_step(st);
    sqlite3_finalize(st);

    sqlite3_prepare_v2(g_db,
        "SELECT account_id FROM accounts WHERE account_name = 'PLAYER1';",
        -1, &st, NULL);
    if (sqlite3_step(st) == SQLITE_ROW) *account_id = sqlite3_column_int(st, 0);
    else *rc = 3;
    sqlite3_finalize(st);
}

/* tier: raw space-padded PIC X(10), bound by length, never strlen'd */
void db_record_run(int *account_id, int *final_balance, int *overdrafts,
                    char *tier, int *won, int *rc)
{
    *rc = 0;
    if (!g_db) { *rc = 1; return; }

    int tlen = 10;
    while (tlen > 0 && tier[tlen - 1] == ' ') tlen--;

    time_t now = time(NULL);
    char stamp[32];
    strftime(stamp, sizeof(stamp), "%Y-%m-%d %H:%M:%S", gmtime(&now));

    sqlite3_stmt *st;
    const char *sql =
        "INSERT INTO ledger_entries"
        " (account_id, played_at, final_balance, overdrafts, tier, won)"
        " VALUES (?, ?, ?, ?, ?, ?);";
    if (sqlite3_prepare_v2(g_db, sql, -1, &st, NULL) != SQLITE_OK) { *rc = 2; return; }
    sqlite3_bind_int(st, 1, *account_id);
    sqlite3_bind_text(st, 2, stamp, -1, SQLITE_STATIC);
    sqlite3_bind_int(st, 3, *final_balance);
    sqlite3_bind_int(st, 4, *overdrafts);
    sqlite3_bind_text(st, 5, tier, tlen, SQLITE_STATIC);
    sqlite3_bind_int(st, 6, *won);
    if (sqlite3_step(st) != SQLITE_DONE) *rc = 3;
    sqlite3_finalize(st);
}

/* count, max(final_balance), sum(overdrafts) over one account's history */
void db_account_summary(int *account_id, int *runs_played,
                         int *best_balance, int *total_overdrafts, int *rc)
{
    *rc = 0;
    *runs_played = 0;
    *best_balance = 0;
    *total_overdrafts = 0;
    if (!g_db) { *rc = 1; return; }

    sqlite3_stmt *st;
    const char *sql =
        "SELECT COUNT(*), COALESCE(MAX(final_balance),0),"
        "       COALESCE(SUM(overdrafts),0)"
        " FROM ledger_entries WHERE account_id = ?;";
    if (sqlite3_prepare_v2(g_db, sql, -1, &st, NULL) != SQLITE_OK) { *rc = 2; return; }
    sqlite3_bind_int(st, 1, *account_id);
    if (sqlite3_step(st) == SQLITE_ROW) {
        *runs_played       = sqlite3_column_int(st, 0);
        *best_balance      = sqlite3_column_int(st, 1);
        *total_overdrafts  = sqlite3_column_int(st, 2);
    } else {
        *rc = 3;
    }
    sqlite3_finalize(st);
}

void db_shutdown(void)
{
    if (g_db) { sqlite3_close(g_db); g_db = NULL; }
}
