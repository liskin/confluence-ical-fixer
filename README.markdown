# Fix iCal from Confluence for import into Google Calendar

A simple tool that fixes ical exports from Confluence Team Calendars so that
they can be correctly imported into Google Calendar.

# Usage

    $ cabal install
    $ perl -p -0777 -e 's/CN=(.*?);/CN="$1";/gs' <xxx.ics | confluence-ical-fixer >xxx-fixed.ics
