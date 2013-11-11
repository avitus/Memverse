var quizRoom = {

    numQuestions: null,
    userIDArray:  [],

    initialize: function ( numQuestions ) {

        this.numQuestions     = numQuestions;

    },

    /******************************************************************************
     * Handle real-time quiz messages
     ******************************************************************************/
    handleMessage: function (m) {
        switch(m.meta) {
            case "chat":
                var first_colon  = parseInt(m.data.indexOf(':'));
                var sender_id    = m.data.substring(0,first_colon);
                var second_colon = parseInt(m.data.indexOf(':',first_colon+1));
                var user         = m.data.substring(first_colon+1,second_colon);
                var message      = m.data.substring(second_colon+1);

                this.putChat(user,message,m.meta,sender_id);

                break;
            case "chat_status":
                $("#chat_status").text(m.status);
                var user    = "Memverse Server"
                var message = "Chat Channel " + m.status;

                this.putChat(user,message,m.meta);

                break;
            case "question":
                this.handleQuestion(m);

                break;
            case "scoreboard":
                this.updateScoreboard(m);

                break;
        }
    },

    /******************************************************************************
     * Handle questions
     ******************************************************************************/
    handleQuestion: function (data) {

        var qNum   = data.q_num;
        var qType  = data.q_type;
        var qTime  = data.time_alloc;
        var qID    = data.q_id;

        var qText, qRef, qShow, qAnswer;
        var qOptionA, qOptionB, qOptionC, qOptionD, mcAnswer;

        // Set what should be displayed (question) and hidden (answer)
        switch (qType)
        {
            case 'recitation':
                qRef    = data.q_ref;
                qText   = data.q_passages[translation];
                qShow   = qRef;
                qAnswer = qText;
            break;

            case 'reference':
                qRef    = data.q_ref;
                qText   = data.q_passages[translation];
                qShow   = qText;
                qAnswer = qRef;
            break;

            case 'mcq':
                qText    = data.mc_question;
                qOptionA = data.mc_option_a;
                qOptionB = data.mc_option_b;
                qOptionC = data.mc_option_c;
                qOptionD = data.mc_option_d;
                mcAnswer = data.mc_answer;
                qShow    = qText;
                qAnswer  = data.mc_answer;
            break;

            default:
                qShow = 'Error'
        }

        $(".q-dot.current").removeClass("current");
        $("#dot-"+qNum).addClass("current");

        var p   = $("<p/>").text(qShow);
        var q   = "#question-"+qNum;

        $(q+" #q-question").html(p);
        $(q+" #q-question").scrollTop($(q)[0].scrollHeight);

        $(".question").hide();
        $(q).show();

        // Set up question depending on type
        if (qType == 'reference' || qType == 'recitation') {

            quizRoom.addInputBox( qType, qNum, qAnswer);

        } else if (qType == 'mcq'){

            $(q+" #q-answer").html( setupMCQ( qOptionA, qOptionB, qOptionC, qOptionD, mcAnswer ) );
            $('input#submit-answer').on( "click", function() { quizRoom.scoreUserAnswer( qAnswer, qType, qNum, qID ); } );

        };

        // Start countdown clock
        quizRoom.setCountdownClock( qTime, qNum );

    },

    setCountdownClock: function( questionDuration, questionNum ) {
        // countdown clock
        $('#quiz-timer').countdown('destroy').removeClass('red-highlight');
        $('#quiz-timer').countdown({until: +questionDuration, onTick: this.highlightLast5, onExpiry: this.disableSubmission, format: 'S'});

        if (questionNum == this.numQuestions ) { // if last question

            // countdown till question and quiz over
            $("#countdown-till").text("till question and quiz over");

            // setTimeout to put up "Finished" status message when it's done
            setTimeout( function() {
                $("#countdown-till").html("<strong>Quiz Status:</strong> Finished").effect('highlight', {}, 3000);
                $('#quiz-timer').countdown('destroy').removeClass('red-highlight');
                quizRoom.disableSubmission();
            }, questionDuration * 1000);

        } else {
            $("#countdown-till").text("till next question");
        }
    },

    /******************************************************************************
     * Score and record answer
     ******************************************************************************/
    scoreUserAnswer: function( questionAnswer, questionType, questionNum, questionID ) {

        var userAnswer = $('input[name=mcq]:checked').val();

        $('input#submit-answer').remove();  // remove answer submission button

        grade = getScore( questionAnswer, userAnswer, questionType );

        if (grade.score != null) {

            // Record score and update question difficulty
            $.post("/record_score", {   usr_id:       memverseUserID,
                                        usr_name:     memverseUserName,
                                        usr_login:    memverseUserLogin,
                                        question_id:  questionID,
                                        question_num: questionNum,
                                        score:        grade.score } );

            selector = "#question-" + questionNum;
            $(selector + " #q-msg").html("<p>" + grade.msg + "</p>").children("p").effect('highlight', {}, 3000);
            if (grade.score != 10) { // if it's wrong
                $(selector + " #q-answer input#opt_" + userAnswer).parent().addClass("incorrect");
                $(".q-dot.current").addClass("red");
            } else {
                $(".q-dot.current").addClass("green");
            }
            $(selector + " #q-answer:visible input#opt_" + questionAnswer.toLowerCase()).parent().addClass("correct");
            $(selector + " #q-msg q-answer input").remove();
        }
    },

    /******************************************************************************
     * Disable question submission
     ******************************************************************************/
    disableSubmission: function () {
        $('input#submit-answer').hide();
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

        // TODO: This duplicates a lot of code above
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
                if(grade.score == 10){
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
    putChat: function (user,message,meta,sender_id){

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
    updateScoreboard: function (data){

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

/******************************************************************************
 * Callback function to handle initial connection when subscribing to PubNub
 ******************************************************************************/
function mvConnect( pubnub ) {
    pubnub.here_now({
        channel  : channel,
        callback : mvPresence
    });
};

/******************************************************************************
 * Callback function to handle users joining/leaving channel and on connection
 ******************************************************************************/
function mvPresence ( message, env, channel ) {

    var roster_uid   = message.uuid;

    console.log('===> Presence callback: ')

    // --- User joins quiz ---
    if (message.action == "join") {

        $.getJSON('/users/'+ message.uuid +'.json', function( data ) {

            var roster_uname = data.name;
            var gravatar_url = data.avatar_url;
            var user_link    = build_user_link(roster_uid, roster_uname);
            var joinMsg      = $("<li/>").addClass("chat-announcement").append(user_link + " joined the quiz.");

            // Add user to roster array
            quizRoom.userIDArray.push({ id: data.id, name: data.name, avatarURL: data.avatar_url, userLink: user_link });

            // copied from Juggernaut code ... optimize this
            var div = $(build_roster_item( roster_uid, roster_uname, gravatar_url ));
            $("#roster-window").scrollTop($("#roster-window")[0].scrollHeight).append(div);
            div.effect('highlight', {}, 3000);
            $("#quizzers-stats").effect('highlight', {}, 3000);
            $("#quizzers-count").html("(" + $("div.roster-item").length + ")");

            // Add user joins message to chat window
            chat_stream_scroll( function () {
                $("#chat-stream-narrow").append( joinMsg );
            });
        });

    // --- User leaves quiz ---
    } else if (message.action == "leave") {

        var departedUser = quizRoom.userIDArray.splice( quizRoom.userIDArray.indexOf( roster_uid ), 1 );
        var li           = $("<li/>").addClass("chat-announcement").append(departedUser[0].userLink + " left the room.");

        // copied from Juggernaut code ... optimize me
        $("div#" + roster_uid).remove();
        $("#quizzers-count").html("(" + $("div.roster-item").length + ")");

        chat_stream_scroll( function () {
            $("#chat-stream-narrow").append(li);
        });

    } else if (message.action == "timeout" ) {

        // Need to handle timeouts ... not sure how

    // --- Create roster when joining ---
    } else {
        // quizRoom.userIDArray = message.uuids;
        console.log("Joining quiz room: " + quizRoom.userIDArray );
        console.log("Event            : " + env );
        console.log("Channel          : " + channel );
    }

};




