function _atuin_ai_question_mark_insert
    if test -z (commandline -b)
        _atuin_ai_question_mark
    else
        commandline -i "?"
    end
end
