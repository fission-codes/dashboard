module Recovery.Api exposing (..)

import Http
import Recovery.Radix exposing (Endpoints)


sendRecoveryEmail : { endpoints : Endpoints, username : String, onResult : Result Http.Error () -> msg } -> Cmd msg
sendRecoveryEmail { endpoints, username, onResult } =
    Http.request
        { method = "POST"
        , headers = []
        , url = endpoints.api ++ "/user/email/recover/" ++ username
        , body = Http.emptyBody
        , expect = Http.expectWhatever onResult
        , timeout = Just 10000
        , tracker = Nothing
        }
