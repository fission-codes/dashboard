module Recovery.Route exposing (..)

import Browser
import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query as Query


parseChallenge : Url -> Maybe String
parseChallenge url =
    Maybe.andThen (\m -> m) (parse challengeParser url)


challengeParser : Parser (Maybe String -> b) b
challengeParser =
    top </> s "recover" <?> Query.string "challenge"


detectExternal : Browser.UrlRequest -> Browser.UrlRequest
detectExternal request =
    case request of
        Browser.Internal url ->
            case parse (map () (top </> s "recover")) url of
                Just _ ->
                    request

                Nothing ->
                    Browser.External (Url.toString url)

        _ ->
            request
