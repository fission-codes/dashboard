port module Ports exposing
    ( appDelete
    , appDeleteFailed
    , appDeleteSucceeded
    , appRename
    , appRenameFailed
    , appRenameSucceeded
    , copyElementToClipboard
    , fetchReadKey
    , fetchReadKeyError
    , fetchedReadKey
    , log
    , logout
    , redirectToLobby
    , urlChanged
    , webnativeAppIndexFetch
    , webnativeAppIndexFetched
    , webnativeError
    , webnativeInitialized
    , webnativeRequest
    , webnativeResendVerificationEmail
    , webnativeResponse
    , webnativeVerificationEmailSent
    )

import Data.App as App
import Json.Decode as Json
import Json.Encode as E
import Webnative
import Webnative.Types


port log : List Json.Value -> Cmd msg


port urlChanged : (String -> msg) -> Sub msg



-- Webnative-Elm Ports


port webnativeRequest : Webnative.Request -> Cmd msg


port webnativeResponse : (Webnative.Response -> msg) -> Sub msg



-- Webnative Ports


port webnativeInitialized : (Json.Value -> msg) -> Sub msg


port webnativeResendVerificationEmail : {} -> Cmd msg


port webnativeVerificationEmailSent : ({} -> msg) -> Sub msg


port webnativeError : (String -> msg) -> Sub msg



-- Secure Backup


port fetchReadKey : () -> Cmd msg


port fetchedReadKey : ({ key: String, createdAt : String } -> msg) -> Sub msg


port fetchReadKeyError : (String -> msg) -> Sub msg


port copyElementToClipboard : String -> Cmd msg



-- App Index


port webnativeAppIndexFetch : () -> Cmd msg


port webnativeAppIndexFetched : (Json.Value -> msg) -> Sub msg



-- App Delete


appDelete : App.Name -> Cmd msg
appDelete app =
    webnativeAppDelete (App.encode app)


port webnativeAppDelete : Json.Value -> Cmd msg


appDeleteSucceeded : (App.Name -> msg) -> (Json.Error -> msg) -> Sub msg
appDeleteSucceeded onSuccess onError =
    webnativeAppDeleteSucceeded
        (\json ->
            case Json.decodeValue (Json.field "app" App.decoder) json of
                Ok app ->
                    onSuccess app

                Err error ->
                    onError error
        )


port webnativeAppDeleteSucceeded : (Json.Value -> msg) -> Sub msg


appDeleteFailed : (App.Name -> String -> msg) -> (Json.Error -> msg) -> Sub msg
appDeleteFailed onSuccess onError =
    webnativeAppDeleteFailed
        (\json ->
            case
                Json.decodeValue
                    (Json.map2 onSuccess
                        (Json.field "app" App.decoder)
                        (Json.field "error" Json.string)
                    )
                    json
            of
                Ok msg ->
                    msg

                Err error ->
                    onError error
        )


port webnativeAppDeleteFailed : (Json.Value -> msg) -> Sub msg



-- App Rename


appRename : { from : App.Name, to : App.Name } -> Cmd msg
appRename { from, to } =
    webnativeAppRename
        (E.object
            [ ( "from", E.string (App.toString from) )
            , ( "to", E.string (App.toString to) )
            ]
        )


port webnativeAppRename : Json.Value -> Cmd msg


appRenameSucceeded : ({ app : App.Name, renamed : App.Name } -> msg) -> (Json.Error -> msg) -> Sub msg
appRenameSucceeded onSuccess onError =
    webnativeAppRenameSucceeded
        (\json ->
            case
                Json.decodeValue
                    (Json.map2
                        (\app renamed -> onSuccess { app = app, renamed = renamed })
                        (Json.field "app" App.decoder)
                        (Json.field "renamed" App.decoder)
                    )
                    json
            of
                Ok msg ->
                    msg

                Err error ->
                    onError error
        )


port webnativeAppRenameSucceeded : (Json.Value -> msg) -> Sub msg


appRenameFailed : (App.Name -> String -> msg) -> (Json.Error -> msg) -> Sub msg
appRenameFailed onSuccess onError =
    webnativeAppRenameFailed
        (\json ->
            case
                Json.decodeValue
                    (Json.map2 onSuccess
                        (Json.field "app" App.decoder)
                        (Json.field "error" Json.string)
                    )
                    json
            of
                Ok msg ->
                    msg

                Err error ->
                    onError error
        )


port webnativeAppRenameFailed : (Json.Value -> msg) -> Sub msg



--


redirectToLobby : { permissions : Webnative.Types.Permissions } -> Cmd msg
redirectToLobby { permissions } =
    webnativeRedirectToLobby { permissions = Webnative.Types.encodePermissions permissions }


port webnativeRedirectToLobby : { permissions : Json.Value } -> Cmd msg


port logout : () -> Cmd msg
