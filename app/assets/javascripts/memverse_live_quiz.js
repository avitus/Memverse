var quizRoom = {

    numQuestions: null,
    userIDArray:  [],

    initialize: function ( numQuestions ) {

        this.numQuestions     = numQuestions;

    },

    /******************************************************************************
     * Handle questions
     ******************************************************************************/
    handle_question: function (data) {
        var q_num  = data.q_num;
        var q_type = data.q_type;
        var q_text;
        var q_ref;
        var q_show;
        var q_ansr;

        var mc_option_a;
        var mc_option_b;
        var mc_option_c;
        var mc_option_d;
        var mc_answer;

        if (q_type != 'mcq') {
            q_ref  = data.q_ref;
            q_text = data.q_passages[translation];
        } else {
            q_text     = data.mc_question;
            q_option_a = data.mc_option_a;
            q_option_b = data.mc_option_b;
            q_option_c = data.mc_option_c;
            q_option_d = data.mc_option_d;
            mc_answer  = data.mc_answer;
        }
        q_time = data.time_alloc;

        switch (q_type)
        {
            case 'recitation':
              q_show = q_ref;
              q_ansr = q_text;
            break;

            case 'reference':
              q_show = q_text;
              q_ansr = q_ref;
            break;

            case 'mcq':
              q_show = q_text;
              q_ansr = mc_answer;
            break;

            default:
              q_show = 'Error'
        }

        $(".q-dot.current").removeClass("current");
        $("#dot-"+q_num).addClass("current");

        var p   = $("<p/>").text(q_show);
        var q   = "#question-"+q_num;

        $(q+" #q-question").html(p);
        $(q+" #q-question").scrollTop($(q)[0].scrollHeight);

        $(".question").hide();
        $(q).show();

        if(q_type == 'reference' || q_type == 'recitation'){
            addInputBox(q_type, q_num, q_ansr);
        } else if (q_type == 'mcq'){

            $(q+" #q-answer").html( setupMCQ(q_option_a, q_option_b, q_option_c, q_option_d, mc_answer) );

            $('input#submit-answer').click(function() {
                $(this).remove();
                var userAnswer = $('input[name=mcq]:checked').val();
                grade = getScore(q_ansr, userAnswer, q_type);
                if (grade.score != null) {
                    $.post("/record_score", {   usr_id:     memverseUserID,
                                                usr_name:   memverseUserName,
                                                usr_login:  memverseUserLogin,
                                                score:      grade.score } );

                    selector = "#question-" + q_num;
                    $(selector + " #q-msg").html("<p>" + grade.msg + "</p>").children("p").effect('highlight', {}, 3000);
                    if (grade.score != 15) { // if it's wrong
                        $(selector + " #q-answer input#opt_" + userAnswer).parent().addClass("incorrect");
                        $(".q-dot.current").addClass("red");
                    } else {
                        $(".q-dot.current").addClass("green");
                    }
                    $(selector + " #q-answer:visible input#opt_" + q_ansr.toLowerCase()).parent().addClass("correct");
                    $(selector + " #q-msg q-answer input").remove();
                }
            });
        }

        // countdown clock
        $('#quiz-timer').countdown('destroy').removeClass('red-highlight');
        $('#quiz-timer').countdown({until: +q_time, onTick: this.highlightLast5, onExpiry: this.disableSubmission, format: 'S'});

        if (q_num == this.numQuestions ) { // if last question
            // countdown till question and quiz over
            $("#countdown-till").text("till question and quiz over");
            // setTimeout to put up "Finished" status message when it's done
            setTimeout( function() {
                $("#countdown-till").html("<strong>Quiz Status:</strong> Finished").effect('highlight', {}, 3000);
                $('#quiz-timer').countdown('destroy').removeClass('red-highlight');
                quizRoom.disableSubmission();
            },q_time*1000);
        } else {
            $("#countdown-till").text("till next question");
        }
    },

    /******************************************************************************
     * Disable question submission
     ******************************************************************************/
    disableSubmission: function () {
        $('input#submit-answer').hide();
    },

    /******************************************************************************
     * Handle real-time quiz messages
     ******************************************************************************/
    handle_message: function (m) {
        switch(m.meta) {
            case "chat":
                var first_colon  = parseInt(m.data.indexOf(':'));
                var sender_id    = m.data.substring(0,first_colon);
                var second_colon = parseInt(m.data.indexOf(':',first_colon+1));
                var user         = m.data.substring(first_colon+1,second_colon);
                var message      = m.data.substring(second_colon+1);

                this.put_chat(user,message,m.meta,sender_id);

                break;
            case "chat_status":
                $("#chat_status").text(m.status);
                var user    = "Memverse Server"
                var message = "Chat Channel " + m.status;

                this.put_chat(user,message,m.meta);

                break;
            case "question":
                this.handle_question(m);

                break;
            case "scoreboard":
                this.update_scoreboard(m);

                break;
        }
    },


    /******************************************************************************
     * Add correct question input form
     ******************************************************************************/
    addInputBox: function (questionType, questionNum, questionAnswer) {
        selector = "#question-" + questionNum;
        switch(questionType) {
            case 'recitation':
                $(selector + " #q-answer").html("<textarea class='q-answer-input' name='txt" + questionNum + "' id='" + questionNum + "'></textarea>");
                $(selector + " #q-answer").append("<br/>")
                $(selector + " #q-answer").append("<input type='submit' value='Answer!' id='submit-answer' class='button-link'>");
                if (!$('#msg_body').is(':focus')) {
                    $("textarea#" + questionNum).focus();
                }
                break;

            case 'reference':
                $(selector + " #q-answer").html("<input type='text' class='q-answer-input' name='txt" + questionNum + "' id='" + questionNum + "'</input>");
                $(selector + " #q-answer").append("<input type='submit' value='Answer!' id='submit-answer' class='button-link'>");
                $(selector + ' #q-answer input[type="text"]').autocomplete({ source: ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
                    '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalm', 'Proverbs',
                    'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel',
                    'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
                    'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
                    'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
                    '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']
                });
                if (!$('#msg_body').is(':focus')) {
                    $(selector + ' #q-answer input[type="text"]').focus();
                }
                break;

            case 'mcq':
                break;

            default:
                $(selector + " #q-answer").html("<input type='text' class='q-answer-input'" + "name='txt" + questionNum + "' id='" + questionNum + "'</input>");
                $(selector + " #q-answer").append("<input type='submit' value='Answer!' id='submit-answer' class='button-link'>");
        }

        $('input#submit-answer').click(function() {
            var userAnswer = $('.q-answer-input').val();
            grade = getScore(questionAnswer, userAnswer, questionType);
            if (grade.score != null) {
                $.post("/record_score", { usr_id:     memverseUserID,
                                          usr_name:   memverseUserName,
                                          usr_login:  memverseUserLogin,
                                          score:      grade.score } );
                $(selector + " #q-msg").html("<p>" + grade.msg + "</p>").children("p").effect('highlight', {}, 3000);
                $(selector + " #q-answer").html("<strong>Your answer: </strong>" + userAnswer);

                // make q-dot red or green, depending on score
                if(grade.score == 15){
                    $(".q-dot.current").addClass("green");
                } else {
                    $(".q-dot.current").addClass("red");
                }
            }
        });
    },

    /******************************************************************************
     * Add message to chat window
     ******************************************************************************/
    put_chat: function (user,message,meta,sender_id){

        var u = $("<li/>").text(user).addClass("chat-username");
        var m = $("<li/>").text(message).addClass("chat-message");

        u.attr("id",sender_id); // add sender_id if present

        if ((u.text() == $("#chat-stream-narrow li.chat-username").last().text()) && ($("#chat-stream-narrow li").last().attr('class') != 'chat-announcement')) {
            u = "";
        }

        chat_stream_scroll(function(){
            $("#chat-stream-narrow").append(u).append(m);
        });

    },

    /******************************************************************************
     * Update quiz scoreboard
     ******************************************************************************/
    update_scoreboard: function (data){

        $("#live-quiz-scores").empty();

        $.each(data.scoreboard, function(i, item) {

            var user    = item.name + " ";
            var score   = item.score;
            var li      = $("<li/>");
            var u       = $("<span/>");
            var s       = $("<span/>");

            u.text(user).addClass("scoreboard-username");
            s.text(score).addClass("scoreboard-score");

            if(item.login == "<%= current_user.login %>"){
                li.addClass("hilite");
            }

            li.append(u).append(s);

            $("#live-quiz-scores").append(li);
            $("#live-quiz-scores").scrollTop(0);
        });
    },

    /******************************************************************************
     * Highlight last five seconds of countdown timer
     ******************************************************************************/
    highlightLast5: function (periods) {
        if ($.countdown.periodsToSeconds(periods) == 5) {
            $(this).addClass('red-highlight');
        }
    },

    /******************************************************************************
     * Show quizzers
     ******************************************************************************/
    toggleQuizzersWindow: function () {
        if( $('#roster-window').is(':visible') ) {
            $('#roster-window').slideUp();
            $(this).removeClass('expanded');
        } else {
            $('#roster-window').slideDown();
            $(this).addClass('expanded');
        }
    }

} // end of quizRoom scope


/******************************************************************************
 * Display full list of verses
 * Input: single verse OR array of verses
 ******************************************************************************/
function displayMultiTranslationSearchResultsFn( verses ) {

    $('.supporting-ref-display').empty(); // Clear prior results

    if (!verses) return;  // nothing to display

    // wrap single verse in array
    if( !($.isArray(verses)) ) {
        verses = [ verses ];
    }

    $.each (verses, function(i, vs) {

        // Build HTML for each verse
        var $new_vs = $('<div/>').addClass('item')

            // verse reference
            .append( $('<div class="ref-and-details" />')
                .append($('<h5 class="ref"         />').text( vs.tl   ))
                .append($('<p  class="first-words" />').text( vs.text )) // re-using class from learn page
            );

        // Display verse on page
        $('.supporting-ref-display').filter(':last').append($new_vs);
    });
};

/******************************************************************************
 * Only submit chat messages with text
 ******************************************************************************/
function mvSubmitQuizChat() {
    if ($("#msg_body").val() == "") {
        alert("Please put text in your message.");
        return false;
    }
    else {
        return true;
    }
}




