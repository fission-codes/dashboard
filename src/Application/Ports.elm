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



-- App Index


port webnativeAppIndexFetch : () -> Cmd msg


port webnativeAppIndexFetched : (Json.Value -> msg) -> Sub msg



-- App Delete


port webnativeAppDelete : Json.Value -> Cmd msg


port webnativeAppDeleteSucceeded : (Json.Value -> msg) -> Sub msg


port webnativeAppDeleteFailed : (Json.Value -> msg) -> Sub msg



-- App Rename


port webnativeAppRename : Json.Value -> Cmd msg


port webnativeAppRenameSucceeded : (Json.Value -> msg) -> Sub msg


port webnativeAppRenameFailed : (Json.Value -> msg) -> Sub msg



--


port webnativeRedirectToLobby : () -> Cmd msg
