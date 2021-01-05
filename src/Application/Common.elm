module Common exposing (..)


when : Bool -> List a -> List a
when predicate list =
    if predicate then
        list

    else
        []
