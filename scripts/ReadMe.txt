NinjaTrader 8 outside OneDrive - the data-folder link
=====================================================

NinjaTrader keeps everything (indicators, templates, workspaces, its database)
in Documents\NinjaTrader 8. When Documents is synced by OneDrive that folder
gets synced too, which NinjaTrader does not like. The fix is a junction: the
Documents\NinjaTrader 8 entry is a link, and the real folder is
C:\NinjaTrader8Data, which OneDrive never sees.

The one thing the junction cannot survive is the NinjaTrader INSTALLER. It
reads file attributes through the link, fails with error 2330, and rolls back
(measured 2026-10-20 on 8.1.8.4). So an update is three clicks, never a
reinstall:

UPDATING NINJATRADER
--------------------
  1) Close NinjaTrader. Double-click  NinjaTrader8_1_BeforeUpdate.bat
     (click Yes on the administrator prompt). It turns Documents\NinjaTrader 8
     back into a plain folder by renaming the data folder into place. Nothing
     is copied or deleted.
  2) Run the NinjaTrader installer. Leave "launch NinjaTrader" unticked.
  3) Double-click  NinjaTrader8_2_AfterUpdate.bat  (administrator prompt again),
     or simply start NinjaTrader through  JournifiAI-NT-Launcher.bat  which
     does the same thing on every launch:
       - the junction comes back and the data folder returns to C:\NinjaTrader8Data,
       - the GC performance paragraph is merged into the new NinjaTrader.exe.config
         (the installer ships a fresh one without it; the old file is never
         copied over the new one, because its assembly redirects would be stale).
         The installer's untouched config is kept in the config-backups folder
         beside these scripts, so Program Files stays exactly as NinjaTrader shipped it.
  If step 3 says the folder could not be moved, wait a minute and run it again:
  antivirus or the search indexer was still reading the freshly moved files.
  Anything the scripts have to move out of the way is KEPT beside it with a
  date stamp ("NinjaTrader 8.replaced-<date>"); delete those yourself once
  NinjaTrader runs happily.

FIRST TIME on a machine
-----------------------
  1) Close NinjaTrader.
  2) Run  NinjaTrader8_EnsureLink.bat  as administrator. It moves
     Documents\NinjaTrader 8 to C:\NinjaTrader8Data and creates the link
     (a cross-drive move keeps the original as "NinjaTrader 8.migrated-<date>").
  3) Run  0NinjaTrader8_CheckLink.bat  - it should say LINKED.

ANY TIME
--------
  0NinjaTrader8_CheckLink.bat  - read-only, shows how the link is wired.

Notes
-----
  - The scripts find your Documents folder the same way NinjaTrader does, so
    they work whether Documents is under OneDrive or not. No per-person edits.
  - They never kill NinjaTrader. If it is open they stop and ask you to close it.
  - Administrator rights are needed because the data folder sits at the root
    of C:. The two numbered files and the launcher ask for them themselves.
  - If your data folder is somewhere other than C:\NinjaTrader8Data, pass that
    path as the first argument, e.g.  NinjaTrader8_EnsureLink.bat D:\NT8Data
  - 1NinjaTrader8_JunctionPointScript.bat and 2NinjaTrader8_JunctionPointScript.bat
    are the older one-off versions (the 2 was a custom copy for one tester's
    OneDrive layout). EnsureLink replaces both.
