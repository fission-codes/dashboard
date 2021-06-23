module Recovery.Api exposing (..)

import Http
import Json.Encode as E
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


updateUserDID :
    { endpoints : Endpoints
    , username : String
    , publicKey : String
    , challenge : String
    , onResult : Result Http.Error () -> msg
    }
    -> Cmd msg
updateUserDID { endpoints, username, publicKey, challenge, onResult } =
    Http.request
        { method = "PUT"
        , headers = []
        , url = endpoints.api ++ "/user/did/" ++ username ++ "?challenge=" ++ challenge
        , body = Http.jsonBody (E.string publicKey)
        , expect = Http.expectWhatever onResult
        , timeout = Just 10000
        , tracker = Nothing
        }
