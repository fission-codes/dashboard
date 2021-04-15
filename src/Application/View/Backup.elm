module View.Backup exposing (..)

import Css.Global
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, href, src, tabindex, target, title, type_, value)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, px)
import View.Dashboard


view : Html msg
view =
    text ""
