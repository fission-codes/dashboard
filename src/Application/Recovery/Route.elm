module Recovery.Route exposing (..)

import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query as Query


parseChallenge : Url -> Maybe String
parseChallenge url =
    Maybe.andThen (\m -> m) (parse challengeParser url)


challengeParser : Parser (Maybe String -> b) b
challengeParser =
    top </> s "recover" <?> Query.string "challenge"
