var url = 'http://www.eletd.com/rewards_data.js'

function GetLadderData() {
    $.Msg("Getting Rewards data...")
    $.AsyncWebRequest( url, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            $.Msg(info)
        }
    })
}
