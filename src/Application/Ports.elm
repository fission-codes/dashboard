port module Ports exposing (..)

import Webnative


port webnativeRequest : Webnative.Request -> Cmd msg


port wnfsRequest : Webnative.Request -> Cmd msg


port wnfsResponse : (Webnative.Response -> msg) -> Sub msg
