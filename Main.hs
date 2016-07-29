{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wall -fno-warn-incomplete-patterns #-}

import Data.Default
import Data.Time.LocalTime
import Data.Time.Clock
import Text.ICalendar
import qualified Data.ByteString.Lazy as L
import qualified Data.Map.Lazy as M
import qualified Data.Set as S
import qualified Data.Text.Lazy as T

main :: IO ()
main = do
    input <- L.getContents
    let cal = case parseICalendar def "stdin" input of
            Right ([c], _) -> c
            Left err -> error err
    L.putStr $ printICalendar def $ fixEvents cal

fixEvents :: VCalendar -> VCalendar
fixEvents cal = cal{ vcEvents = es'' }
    where
        es = vcEvents cal
        es' = M.map fixEvent1 es
        es'' = M.mapWithKey fixEvent2 es'

        -- https://jira.atlassian.com/browse/TEAMCAL-2284
        fixEvent1 e@VEvent{ veSummary = Just s@Summary{ summaryValue = st }, veAttendee = (S.toList -> [ Attendee{ attendeeCN = Just a } ]) } =
            e{ veSummary = Just s{ summaryValue = T.concat [a, ": ", st] } }
        fixEvent1 e = e

        fixEvent2 (_, Nothing) e = e
        fixEvent2 (uid, _) e =
            case M.lookup (uid, Nothing) es of
                Just e1 -> fixRecurId e e1
                Nothing -> e

-- http://www.kanzaki.com/docs/ical/recurrenceId.html says:
--
-- > This property is used in conjunction with the "UID" and "SEQUENCE"
-- > property to identify a specific instance of a recurring "VEVENT", "VTODO"
-- > or "VJOURNAL" calendar component. The property value is the effective
-- > value of the "DTSTART" property of the recurrence instance.
--
-- Confluence sets it to local time and our perl script resets it to day only,
-- without time. This function fixes this.
fixRecurId :: VEvent -> VEvent -> VEvent
fixRecurId e@VEvent{ veRecurId = Just recId@RecurrenceIdDateTime{ recurrenceIdDateTime = recDT } }
    VEvent{ veDTStart = Just DTStartDateTime{ dtStartDateTimeValue = startDT } } =
        e{ veRecurId = Just recId{ recurrenceIdDateTime = fixRecurTime recDT startDT } }
fixRecurId e _ = e

fixRecurTime :: DateTime -> DateTime -> DateTime
fixRecurTime recDT@ZonedDateTime{ dateTimeFloating = recDTF }
    ZonedDateTime{ dateTimeFloating = LocalTime{ localTimeOfDay = startTimeOfDay } } =
        recDT{ dateTimeFloating = recDTF{ localTimeOfDay = startTimeOfDay } }
fixRecurTime recDT@UTCDateTime{ dateTimeUTC = recDTU }
    UTCDateTime{ dateTimeUTC = UTCTime{ utctDayTime = startTimeOfDay } } =
        recDT{ dateTimeUTC = recDTU{ utctDayTime = startTimeOfDay } }
fixRecurTime x y = error $ show (x, y)
