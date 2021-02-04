port module Ports exposing (..)

import Json.Decode as Json
import Webnative



-- Webnative-Elm Ports


port webnativeRequest : Webnative.Request -> Cmd msg


port webnativeResponse : (Webnative.Response -> msg) -> Sub msg



-- Webnative Ports


port webnativeInitialized : (Json.Value -> msg) -> Sub msg


port webnativeResendVerificationEmail : {} -> Cmd msg


port webnativeVerificationEmailSent : ({} -> msg) -> Sub msg
