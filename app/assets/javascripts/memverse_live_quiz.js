var quizRoom = {

    numQuestions: null,
    userIDArray:  [],

    initialize: function ( numQuestions ) {

        this.numQuestions     = numQuestions;

    },

    /******************************************************************************
     * Handle real-time quiz messages
     {  
        "meta":"chat",
        "data": {"user":"Andy","user_id":"1","msg":"hello"},
     }
     ******************************************************************************/
    handleMessage: function (m) {

        switch( m.meta ) {

            case "chat":
                console.log("==> Incoming chat");
                this.putChat( m.data.user, m.data.msg, m.meta, m.data.user_id);
                break;

            case "chat_status":
                $("#chat_status").text(m.status);
                var user    = "Memverse Server"
                var message = "Chat Channel " + m.status;

                this.putChat(user,message,m.meta);
                break;

            case "question":
                console.log("==> Incoming question");
                this.handleQuestion(m);
                break;

            case "scoreboard":
                console.log("==> Incoming scoreboard update");
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
            $('input#submit-answer').on( "click", function() { quizRoom.scoreUserAnswer( qAnswer, qType, qNum, qID ); } );

        } else if (qType == 'mcq'){

            $(q+" #q-answer").html( setupMCQ( qOptionA, qOptionB, qOptionC, qOptionD, mcAnswer, qNum ) );
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

        if (questionType == 'mcq'){
            var userAnswer = $('input[name=mcq]:checked').val();
        } else if (questionType == 'recitation') {
            var userAnswer = $('textarea#'+questionNum).val();
        } else if (questionType == 'reference') {
            var userAnswer = $('input#'+questionNum).val();
        }

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

            // Color result and give feedback on question
            selector = "#question-" + questionNum;
            $(selector + " #q-msg").html("<p>" + grade.msg + "</p>").children("p").effect('highlight', {}, 3000);

            if (grade.score != 10){ // if it's wrong
                $(".q-dot.current").addClass("red");
            } else {
                $(".q-dot.current").addClass("green");
            }

            if(questionType == "mcq"){
                // note correct answer
                $("#q" + questionNum + "_opt_" + questionAnswer.toLowerCase()).parent().addClass("correct");
                // if user was wrong, strike out user answer
                if (grade.score != 10) {
                    $("#q" + questionNum + "_opt_" + userAnswer).parent().addClass("incorrect");
                }
            }
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
                $(selector + ' #q-answer input[type="text"]').autocomplete({ source: Object.values(BIBLEBOOKS.en) });
                if (!$('#msg_body').is(':focus')) {
                    $(selector + ' #q-answer input[type="text"]').focus();
                }
                $(selector + ' #q-answer input[type="text"]').keypress(function(e) {
                    if(e.which == 13) {
                        quizRoom.scoreUserAnswer( qAnswer, qType, qNum, qID );
                    }
                });
                break;

            case 'mcq':
                break;

            default:
                $(selector + " #q-answer").html("<input type='text' class='q-answer-input'" + "name='txt" + questionNum + "' id='" + questionNum + "'</input>");
                $(selector + " #q-answer").append("<input type='submit' value='Answer!' id='submit-answer' class='button-link'>");
        }
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
    },

    /******************************************************************************
     * Check if user present
     ******************************************************************************/

     userPresent: function(uuid) {

        for(x = 0; x < quizRoom.userIDArray; x++){
            if (quizRoom.userIDArray[x].id == uuid) return true;
        }

        return false;
     },

}; // end of quizRoom scope


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

    console.log('=======> Checking quiz occupancy')

    pubnub.here_now({  // returns message: { "uuids": ["1","2","3"], "occupancy": 3 }
        channel  : channel,
        callback : mvInitRoster
    });
};

/******************************************************************************
 * Callback function to handle users present on connection
 *
 * message format: {"action": "join", "timestamp": 123432432, "uuid": "memverse-id", "occupancy": 3}
 *
 ******************************************************************************/
function mvInitRoster ( message, env, channel ) {

    console.log("===> | Initialize roster, PubNub connection message: " + message);

    for(x = 0; x < message.uuids.length; x++){
        var roster_uid = message.uuids[x];

        $.getJSON('/users/'+ roster_uid +'.json', function( data ) {

            var userName    = data.name;
            var gravatarURL = data.avatar_url;
            var userLink    = buildUserLink( roster_uid, userName );

            // Add user to roster array
            quizRoom.userIDArray.push({ id: data.id, name: userName, avatarURL: gravatarURL, userLink: userLink });

            // Add user to visual roster
            addUserToRoster( roster_uid, userName, gravatarURL, message.occupancy );
        });
    }

    // Log to console
    console.log("===> | Initial roster occupancy: " + message.occupancy);

}

/******************************************************************************
 * Callback function to handle users joining/leaving channel and on connection
 *
 * message format: {"action": "join", "timestamp": 123432432, "uuid": "memverse-id", "occupancy": 3}
 *
 ******************************************************************************/
function mvPresence ( message ) {

    var roster_uid   = message.uuid;

    // --- User joins quiz ---
    if (message.action == "join") {

        console.log("     --> A user has joined")

        // Don't add user if they are already in the array
        if( quizRoom.userPresent(message.uuid) ) return;

        $.getJSON('/users/'+ message.uuid +'.json', function( data ) {

            var userName    = data.name;
            var gravatarURL = data.avatar_url;
            var userLink    = buildUserLink( roster_uid, userName );
            var joinMsg     = $("<li/>").addClass("chat-announcement").append(userLink + " has arrived.");

            // Add user to roster array
            quizRoom.userIDArray.push({ id: data.id, name: userName, avatarURL: gravatarURL, userLink: userLink });

            // Add user to visual roster
            addUserToRoster( roster_uid, userName, gravatarURL, message.occupancy );

            // Add "[user] joins" message to chat window
            chat_stream_scroll( function () { $("#chat-stream-narrow").append( joinMsg ) });

            // Log to console
            console.log("===> | Presence callback: " + userName + " has joined the quiz.");
            console.log("     | Occupancy        : ", message.occupancy    );
        });

    // --- User leaves quiz ---
    } else if (message.action == "leave") {

        // Remove user from roster array
        var departedUser = quizRoom.userIDArray.splice( quizRoom.userIDArray.indexOf( roster_uid ), 1 );

        if(typeof departedUser[0] !== 'undefined'){
            var li           = $("<li/>").addClass("chat-announcement").append(departedUser[0].userLink + " has left.");

            // Remove user from visual roster
            $("div#" + roster_uid).remove();
            $("#quizzers-count").html("(" + message.occupancy + ")");

            // Add "[user] leavs" message to chat window
            chat_stream_scroll( function () { $("#chat-stream-narrow").append(li) } );

            // Log to console
            console.log("===> Presence callback: " + departedUser + " has left.");
        } else {
            console.log("departedUser[0] undefined");
        }

    } else if (message.action == "timeout" ) {

        // Need to handle timeouts ... not sure how

    }

};

/******************************************************************************
 * Functions for building Roster
 ******************************************************************************/
function buildUserLink( user_id, user_name ) {
    return '<a href="/users/' + user_id + '" target="_blank">' + user_name + '</a>';
}

function buildGravatarImage( gravatarURL ){
    return '<img src="' + gravatarURL + '&s=32" />'; //set size of gravatar to 32x32 pixels
}

function buildRosterItem( user_id, user_name, gravatarURL ) {
    return '<div class="roster-item" id="'+user_id+'">'+buildGravatarImage(gravatarURL) + " " + buildUserLink(user_id,user_name)+'</div>';
}

function addUserToRoster( userID, userName, gravatarURL, userCount ) {

    // Build div and add user to roster
    var userDiv = $( buildRosterItem( userID, userName, gravatarURL ) );
    $("#roster-window").scrollTop( $("#roster-window")[0].scrollHeight ).append( userDiv );
    userDiv.effect('highlight', {}, 3000);

    // Increase number of quizzers
    $("#quizzers-stats").effect('highlight', {}, 3000);
    $("#quizzers-count").html("(" + userCount + ")");
}

/******************************************************************************
 * Scroll chat
 ******************************************************************************/
function chat_stream_scroll( callback ){
    // Check whether user is scrolled down to bottom of stream before keeping them scrolled down
    // NOTE: chat-stream-narrow is 520px high; we're checking against 530 to pull them down a tad if they forgot to scroll all the way down
    if ( ($("#chat-stream-narrow")[0].scrollHeight - 530) <= $("#chat-stream-narrow").scrollTop()){
        callback();
        $("#chat-stream-narrow").scrollTop($("#chat-stream-narrow")[0].scrollHeight);
    } else { // don't scroll
        callback();
    }
}

