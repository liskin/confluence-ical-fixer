import Data.Default
import Text.ICalendar
import qualified Data.ByteString.Lazy as L
import qualified Data.Map.Lazy as M

main = do
    input <- L.getContents
    let Right ([cal], _) = parseICalendar def "stdin" input
    L.putStr $ printICalendar def $ fixEvents cal

fixEvents :: VCalendar -> VCalendar
fixEvents cal = cal{ vcEvents = es' }
    where
        es = vcEvents cal
        es' = M.mapWithKey fixEvent es

        fixEvent _ e = e
