module Book exposing (main)

import ChapterCommon exposing (chapterCommon)
import ElmBook exposing (withChapters)
import ElmBook.ElmCSS exposing (Book, book)


main : Book ()
main =
    book "Book"
        |> withChapters
            [ chapterCommon
            ]
