{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

import Data.Default
import Text.ICalendar
import qualified Data.ByteString.Lazy as L
import qualified Data.Map.Lazy as M
import qualified Data.Set as S
import qualified Data.Text.Lazy as T

import Debug.Trace

main = do
    input <- L.getContents
    let cal = case parseICalendar def "stdin" input of
            Right ([cal], _) -> cal
            Left err -> error err
    L.putStr $ printICalendar def $ fixEvents cal

fixEvents :: VCalendar -> VCalendar
fixEvents cal = cal{ vcEvents = es' }
    where
        es = vcEvents cal
        es' = M.mapWithKey fixEvent es

        -- https://jira.atlassian.com/browse/TEAMCAL-2284
        fixEvent _ e@VEvent{ veSummary = Just s@Summary{ summaryValue = st }, veAttendee = (S.toList -> [ Attendee{ attendeeCN = Just a } ]) } =
            e{ veSummary = Just s{ summaryValue = T.concat [a, ": ", st] } }
        fixEvent _ e = e
