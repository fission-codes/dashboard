module Webnative.Types exposing (..)

import Json.Decode as Json


type State
    = NotAuthorised NotAuthorisedFields
    | AuthSucceeded AuthSucceededFields
    | AuthCancelled AuthCancelledFields
    | Continuation ContinuationFields


type alias NotAuthorisedFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    }


type alias AuthSucceededFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , newUser : Bool
    , throughLobby : Bool
    , username : String
    }


type alias AuthCancelledFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , cancellationReason : String
    , throughLobby : Bool
    }


type alias ContinuationFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , newUser : Bool
    , throughLobby : Bool
    , username : String
    }


type alias Permissions =
    { app : Maybe AppInfo
    , fs : Maybe FileSystemPermissions
    }


type alias AppInfo =
    { name : String
    , creator : String
    }


type alias FileSystemPermissions =
    { privatePaths : List String
    , publicPaths : List String
    }


decoderState : Json.Decoder State
decoderState =
    let
        decoderNotAuthorised =
            Json.map2 NotAuthorisedFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)

        decoderAuthSucceeded =
            Json.map5 AuthSucceededFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "newUser" Json.bool)
                (Json.field "throughLobby" Json.bool)
                (Json.field "username" Json.string)

        decoderAuthCancelled =
            Json.map4 AuthCancelledFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "cancellationReason" Json.string)
                (Json.field "throughLobby" Json.bool)

        decoderContinuation =
            Json.map5 ContinuationFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "newUser" Json.bool)
                (Json.field "throughLobby" Json.bool)
                (Json.field "username" Json.string)
    in
    Json.field "scenario" Json.string
        |> Json.andThen
            (\scenario ->
                case scenario of
                    "NOT_AUTHORISED" ->
                        Json.map NotAuthorised decoderNotAuthorised

                    "AUTH_SUCCEEDED" ->
                        Json.map AuthSucceeded decoderAuthSucceeded

                    "AUTH_CANCELLED" ->
                        Json.map AuthCancelled decoderAuthCancelled

                    "CONTINUATION" ->
                        Json.map Continuation decoderContinuation

                    other ->
                        Json.fail ("Unrecognized 'scenario' field in Webnative.State: '" ++ other ++ "'")
            )


decoderPermissions : Json.Decoder Permissions
decoderPermissions =
    Json.map2 Permissions
        (Json.maybe (Json.field "app" decoderAppInfo))
        (Json.maybe (Json.field "fs" decoderFileSystemPermissions))


decoderAppInfo : Json.Decoder AppInfo
decoderAppInfo =
    Json.map2 AppInfo
        (Json.field "name" Json.string)
        (Json.field "creator" Json.string)


decoderFileSystemPermissions : Json.Decoder FileSystemPermissions
decoderFileSystemPermissions =
    Json.map2 FileSystemPermissions
        (Json.field "privatePaths" (Json.list Json.string))
        (Json.field "publicPaths" (Json.list Json.string))
