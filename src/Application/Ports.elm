port module Ports exposing (..)

import Json.Decode as Json
import Webnative


port log : List Json.Value -> Cmd msg



-- Webnative-Elm Ports


port webnativeRequest : Webnative.Request -> Cmd msg


port webnativeResponse : (Webnative.Response -> msg) -> Sub msg



-- Webnative Ports


port webnativeInitialized : (Json.Value -> msg) -> Sub msg


port webnativeResendVerificationEmail : {} -> Cmd msg


port webnativeVerificationEmailSent : ({} -> msg) -> Sub msg


port webnativeError : (String -> msg) -> Sub msg


port webnativeAppIndexFetch : () -> Cmd msg


port webnativeAppIndexFetched : (Json.Value -> msg) -> Sub msg


port webnativeAppDelete : String -> Cmd msg


port webnativeAppDeleteFailed : (String -> msg) -> Sub msg


port webnativeRedirectToLobby : () -> Cmd msg
