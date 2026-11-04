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

            case "answer":
                console.log("==> Incoming answer");
                this.revealAnswer(m);
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

        var qShow;
        var qOptionA, qOptionB, qOptionC, qOptionD;

        // Set what should be displayed. The answer arrives once the question has closed.
        switch (qType)
        {
            case 'recitation':
                qShow = data.q_ref;
            break;

            case 'reference':
                qShow = data.q_passages[translation];
            break;

            case 'mcq':
                qOptionA = data.mc_option_a;
                qOptionB = data.mc_option_b;
                qOptionC = data.mc_option_c;
                qOptionD = data.mc_option_d;
                qShow    = data.mc_question;
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

            quizRoom.addInputBox( qType, qNum );
            $('input#submit-answer').on( "click", function() { quizRoom.scoreUserAnswer( qType, qNum ); } );

        } else if (qType == 'mcq'){

            $(q+" #q-answer").html( setupMCQ( qOptionA, qOptionB, qOptionC, qOptionD, qNum ) );
            $('input#submit-answer').on( "click", function() { quizRoom.scoreUserAnswer( qType, qNum ); } );

        };

        // Start countdown clock
        quizRoom.setCountdownClock( qTime, qNum );

    },

    setCountdownClock: function( questionDuration, questionNum ) {
        // countdown clock
        $('#quiz-timer').countdown('destroy').removeClass('red-highlight');
        $('#quiz-timer').countdown({
            until: +questionDuration, 
            onTick: this.highlightLast5, 
            onExpiry: this.disableSubmission, 
            format: 'S',
            labels: ['Years', 'Months', 'Weeks', 'Days', 'Hours', 'Mins', 'Secs'],
            labels1: ['Year', 'Month', 'Week', 'Day', 'Hour', 'Min', 'Sec']
        });

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
     * Send the answer to the server, which grades and records it
     ******************************************************************************/
    scoreUserAnswer: function( questionType, questionNum ) {

        // An enabled button means the question is open and no answer is on its way; Enter can
        // still get here when it isn't
        var submitButton = $('input#submit-answer:enabled');
        if (submitButton.length === 0) { return; }

        if (questionType == 'mcq'){
            var userAnswer = $('input[name=mcq]:checked').val();
        } else if (questionType == 'recitation') {
            var userAnswer = $('textarea#'+questionNum).val();
        } else if (questionType == 'reference') {
            var userAnswer = $('input#'+questionNum).val();
        }

        // Leave the button in place so the player can fix the answer and try again
        var problem = liveQuizAnswerProblem( questionType, userAnswer );
        if (problem) {
            alert(problem);
            return;
        }

        submitButton.prop('disabled', true);  // until the server replies

        var selector = "#question-" + questionNum;
        var dot      = $("#dot-" + questionNum);

        quizRoom.postAnswer( questionNum, userAnswer )
            .done(function (result) {
                submitButton.remove();
                quizRoom.showMessage( selector, liveQuizFeedback(result) );

                if (result.status == 'graded') {
                    dot.addClass( (result.score == 10 ? "green" : "red") + " completed" );
                }
            })
            .fail(function () {
                // If time ran out meanwhile the button is already gone, so this changes nothing
                submitButton.prop('disabled', false);
                quizRoom.showMessage( selector, "Your answer could not be recorded. Please try again, and reload the page if this keeps happening." );
            });
    },

    /******************************************************************************
     * Post to the server. No answer means the question timed out unanswered, which
     * still lists the player on the scoreboard.
     ******************************************************************************/
    postAnswer: function( questionNum, answer ) {
        var data = { quiz_id: quizID, question_num: questionNum };
        if (answer !== undefined) { data.answer = answer; }

        return $.ajax({
            url:      "/record_score",
            type:     "POST",
            dataType: "json",
            headers:  { "X-CSRF-Token": $('meta[name="csrf-token"]').attr('content') },
            data:     data
        });
    },

    /******************************************************************************
     * Add a message under a question
     ******************************************************************************/
    showMessage: function( selector, message ) {
        $("<p/>").text(message).appendTo(selector + " #q-msg").effect('highlight', {}, 3000);
    },

    /******************************************************************************
     * Show the correct answer once the question has closed
     ******************************************************************************/
    revealAnswer: function (data) {

        var qNum     = data.q_num;
        var selector = "#question-" + qNum;
        var message;

        switch (data.q_type)
        {
            case 'mcq':
                var correct  = data.mc_answer.toLowerCase();
                var selected = $(selector + " input[name=mcq]:checked");

                $("#q" + qNum + "_opt_" + correct).parent().addClass("correct");
                if (selected.length > 0 && selected.val() != correct) {
                    selected.parent().addClass("incorrect");
                }
                message = "The correct answer was (" + correct.toUpperCase() + ").";
            break;

            case 'reference':
                message = "The correct reference was " + data.q_ref + ".";
            break;

            case 'recitation':
                message = "The verse reads: " + data.q_passages[translation];
            break;
        }

        if (message) { quizRoom.showMessage( selector, message ); }
    },

    /******************************************************************************
     * Disable question submission and list the player if they didn't answer
     ******************************************************************************/
    disableSubmission: function () {
        var currentQuestion = $('.question:visible');

        // The button is still enabled only if the player hasn't sent an answer
        if ($('input#submit-answer:enabled').length > 0 && currentQuestion.length > 0) {
            quizRoom.postAnswer( currentQuestion.attr('id').replace('question-', '') );
            quizRoom.showMessage( '#' + currentQuestion.attr('id'), "Time's up! No points awarded." );
        }

        // Removed rather than hidden so the check above is false from here on
        $('input#submit-answer').remove();
    },

    /******************************************************************************
     * Add correct question input form
     ******************************************************************************/
    addInputBox: function (questionType, questionNum) {

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
                        quizRoom.scoreUserAnswer( questionType, questionNum );
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

            if(item.login == memverseUserLogin){
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
            $('#quizzers-stats').removeClass('expanded');
        } else {
            $('#roster-window').slideDown();
            $('#quizzers-stats').addClass('expanded');
        }
    },

    /******************************************************************************
     * Check if user present
     ******************************************************************************/

     userPresent: function(userId) {

        for(x = 0; x < quizRoom.userIDArray.length; x++){
            if (quizRoom.userIDArray[x].id == userId) return true;
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

    // PubNub v7+ API with Promise-based approach
    pubnub.hereNow({
        channels: [channel],
        includeUUIDs: true,
        includeState: false
    }).then(function(response) {
        // Extract channel data and convert to v4 format for compatibility
        var channelData = response.channels[channel];
        if (channelData) {
            var message = {
                uuids: channelData.uuids || [],
                occupancy: channelData.occupancy || 0
            };
            mvInitRoster(message);
        }
    }).catch(function(error) {
        console.error('Error getting presence data:', error);
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

    // PubNub v7+ uses 'uuid' for backward compatibility, but also supports 'userId'
    var roster_uid   = message.uuid || message.userId;

    // --- User joins quiz ---
    if (message.action == "join") {

        console.log("     --> A user has joined")

        // Don't add user if they are already in the array
        if( quizRoom.userPresent(roster_uid) ) return;

        $.getJSON('/users/'+ roster_uid +'.json', function( data ) {

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

